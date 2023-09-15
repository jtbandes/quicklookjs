// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Cocoa
import Combine
import Logging
import Quartz
import WebKit

var log = Logger(label: "PreviewVC")

struct GenericError: Error, LocalizedError {
  let message: String

  var errorDescription: String? {
    return message
  }
}

enum Errors: Error {
  case missingWindow
  case unableToCreateEvent
}

enum HandlerName {
  static let `default` = "quicklook"
  static let `internal` = "quicklookInternal"
}

extension WKWebView {
  func callAsyncJavaScript(_ functionBody: String, arguments: [String : Any] = [:], in frame: WKFrameInfo? = nil, in contentWorld: WKContentWorld) -> Future<Any?, Error> {
    return Future { promise in
      self.callAsyncJavaScript(functionBody, arguments: arguments, in: frame, in: contentWorld) {
        promise($0.map(Optional.some))
      }
    }
  }
}

private func makeMouseEvent(_ type: NSEvent.EventType, at location: NSPoint, in window: NSWindow) -> NSEvent? {
  return NSEvent.mouseEvent(
    with: type,
    location: location,
    modifierFlags: [],
    timestamp: CACurrentMediaTime(),
    windowNumber: window.windowNumber,
    context: nil,
    eventNumber: 0,
    clickCount: 1,
    pressure: 0)
}

class PreviewViewController: NSViewController, QLPreviewingController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandlerWithReply {

  let webView: WKWebView
  let configuration: Configuration

  var cancellables = Set<AnyCancellable>()
  var previewedFileURL: URL?
  var loadCompleteFuture: Future<Void, Error>
  var loadCompletePromise: Future<Void, Error>.Promise?

  required init?(coder: NSCoder) { fatalError() }
  override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
    log.logLevel = .debug
    log.debug("init PreviewViewController")

    var promise: Future<Void, Error>.Promise?
    loadCompleteFuture = Future { promise = $0 }
    assert(promise != nil)
    loadCompletePromise = promise

    webView = WKWebView(frame: .zero)

    do {
      configuration = try Configuration.fromMainBundle()
    } catch let error {
      log.error("Unable to load QuickLookJS configuration: \(error.localizedDescription)")
      fatalError("Unable to load QuickLookJS configuration: \(error.localizedDescription)")
    }

    if configuration.drawsBackground == false {
      webView.setValue(configuration.drawsBackground, forKey:"drawsBackground")
    }

    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    if let size = configuration.preferredContentSize {
      preferredContentSize = size
    }
  }

  deinit {
    log.debug("deinit PreviewViewController")
  }

  override func loadView() {
    self.view = webView

    webView.uiDelegate = self
    webView.navigationDelegate = self
    webView.configuration.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: HandlerName.default)
    webView.configuration.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: HandlerName.internal)

    // WKWebView doesn't provide a way to send complex objects (such as File) between content worlds, so any supporting code must go directly in the page world.
    webView.configuration.userContentController.addUserScript(WKUserScript(source: """
let resolve, reject;
window.quicklookPreviewedFile = new Promise((res, rej) => {
  resolve = res;
  reject = rej;
});
window.quicklookPreviewedFile.resolve = resolve;
window.quicklookPreviewedFile.reject = reject;

window.quicklook = {
  async finishedLoading() {
    return webkit.messageHandlers.quicklook.postMessage({ action: "finishedLoading" });
  },
  async getPreviewedFile() {
    await webkit.messageHandlers.quicklook.postMessage({ action: "getPreviewedFile" });
    return window.quicklookPreviewedFile;
  },
};

window.addEventListener("error", (event) => {
  webkit.messageHandlers.quicklookInternal.postMessage({ action: "error", message: event.message });
});
window.addEventListener("unhandledrejection", (event) => {
  webkit.messageHandlers.quicklookInternal.postMessage({ action: "error", message: event.reason.toString() });
});
""", injectionTime: .atDocumentStart, forMainFrameOnly: true))
  }

  override func viewDidLoad() {
    webView.loadFileURL(configuration.pageURL, allowingReadAccessTo: configuration.pageURL)
  }

  func preparePreviewOfFile(at url: URL, completionHandler: @escaping (Error?) -> Void) {
    log.info("begin preparing file", metadata: ["url": "\(url)"])
    assert(previewedFileURL == nil)
    previewedFileURL = url
    loadCompleteFuture.sink {
      log.debug("preparation ended: \($0)")
      if case .failure(let error) = $0 {
        completionHandler(error)
      }
    } receiveValue: {
      log.debug("preparation succeeded: \($0)")
      completionHandler(nil)
    }
    .store(in: &cancellables)
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive scriptMessage: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
    log.debug("got message for \(scriptMessage.name): \(scriptMessage.body)")

    let publisher: AnyPublisher<Any?, Error>

    // Round-trip to JSON in order to make use of JSONDecoder.
    // The standard library provides no Decoder that works directly on a Dictionary.
    // https://elegantchaos.com/2018/02/21/decoding-dictionaries-in-swift.html
    switch scriptMessage.name {
    case HandlerName.default:
      publisher = Result {
        try JSONDecoder().decode(
          ScriptMessage.self,
          from: JSONSerialization.data(withJSONObject: scriptMessage.body))
      }.publisher.flatMap(handleMessage).eraseToAnyPublisher()

    case HandlerName.internal:
      publisher = Result {
        try JSONDecoder().decode(
          InternalScriptMessage.self,
          from: JSONSerialization.data(withJSONObject: scriptMessage.body))
      }.publisher.flatMap(handleInternalMessage).eraseToAnyPublisher()

    default:
      replyHandler(nil, "Unrecognized handler name \(scriptMessage.name)")
      return
    }

    publisher
      .sink {
        log.debug("message handler ended: \($0)")
        if case .failure(let error) = $0 {
          replyHandler(nil, error.localizedDescription)
        }
      } receiveValue: {
        log.debug("message handler succeeded: \($0 ?? "(nil result)")")
        replyHandler($0, nil)
      }
      .store(in: &cancellables)
  }

  private func handleMessage(_ message: ScriptMessage) -> AnyPublisher<Any?, Error> {
    switch message {
    case .finishedLoading:
      loadCompletePromise?(.success(()))
      return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()

    case .getPreviewedFile:
      return webView.callAsyncJavaScript("""
const toHex = (num) => num.toString(16).padStart(2, "0");
const id = Array.from(crypto.getRandomValues(new Uint8Array(16)), toHex).join("");

const input = document.body.appendChild(document.createElement("input"));
input.id = id;
input.type = "file";
input.style.display = "none";

const label = document.body.appendChild(document.createElement("label"));
label.htmlFor = id;
label.style.position = "fixed";
label.style.display = "block";
label.style.margin = "0";
label.style.padding = "0";
label.style.top = "0";
label.style.right = "0";
label.style.bottom = "0";
label.style.left = "0";

input.onchange = (event) => {
  if (event.target.files[0]) {
    window.quicklookPreviewedFile.resolve(event.target.files[0]);
  } else {
    window.quicklookPreviewedFile.reject(new Error("no file was received"));
  }
};

try {
  await webkit.messageHandlers.quicklookInternal.postMessage({action: "clickFileInput"});
  await window.quicklookPreviewedFile;
} finally {
  label.remove();
  input.remove();
}
""", arguments: [:], in: nil, in: .page)
        .mapError { error in
          // Expose the actual underlying error message
          if let wkError = error as? WKError,
             wkError.code == WKError.javaScriptExceptionOccurred,
             let message = wkError.userInfo["WKJavaScriptExceptionMessage"] as? String {
            return GenericError(message: message)
          }
          return error
        }
        .eraseToAnyPublisher()
    }
  }

  private func handleInternalMessage(_ message: InternalScriptMessage) -> AnyPublisher<Any?, Error> {
    switch message {
    case .error(let message):
      log.error("preview page error: \(message)")
      return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()

    case .clickFileInput:
      guard let window = webView.window else {
        return Fail(error: Errors.missingWindow).eraseToAnyPublisher()
      }

      let location = NSPoint(x: webView.frame.midX, y: webView.frame.midY)

      guard let downEvent = makeMouseEvent(.leftMouseDown, at: location, in: window),
            let upEvent = makeMouseEvent(.leftMouseUp, at: location, in: window)
      else {
        return Fail(error: Errors.unableToCreateEvent).eraseToAnyPublisher()
      }

      log.debug("sending click at \(downEvent.locationInWindow)")
      webView.mouseDown(with: downEvent)
      webView.mouseUp(with: upEvent)
      return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
  }

  func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
    if let previewedFileURL = previewedFileURL {
      log.debug("responding to open panel with previewed file url")
      completionHandler([previewedFileURL])
    } else {
      log.warning("open panel request, but no previewed file url")
      completionHandler(nil)
    }
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    log.error("provisional navigation failed", metadata: [
      "error": "\(error.localizedDescription)",
      "navigation": "\(ObjectIdentifier(navigation))"
    ])
    // Can't pass the full error object due to:
    // -[NSXPCEncoder _checkObject:]: This coder only encodes objects that adopt NSSecureCoding (object is of class 'WKReloadFrameErrorRecoveryAttempter').
    // Passing a GenericError for some reason results in Quick Look showing a password prompt.
    loadCompletePromise?(.failure(CocoaError(.fileReadUnknown)))
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    log.debug("navigation finished", metadata: [
      "navigation": "\(ObjectIdentifier(navigation))"
    ])

    switch configuration.loadingStrategy {
    case .navigationComplete:
      log.debug("completing preparation because navigation completed")
      loadCompletePromise?(.success(()))
    case .waitForSignal:
      log.debug("waiting for completion signal")
      break
    }
  }
}
