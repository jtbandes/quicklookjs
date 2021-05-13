//
//  PreviewViewController.swift
//  PreviewExtension
//
//  Created by Work on 5/7/21.
//

import Cocoa
import Quartz
import WebKit

let pboard = NSPasteboard(name: .drag)

class PreviewViewController: NSViewController, QLPreviewingController, WKURLSchemeHandler, WKUIDelegate, NSDraggingSource, WKNavigationDelegate {

    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }
    
    var webView: WKWebView { self.view as! WKWebView }
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        preferredContentSize = NSSize(width: 300, height: 200)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        preferredContentSize = NSSize(width: 300, height: 200)
    }
    
    override func loadView() {
        print("QL preview test loaded!")
        super.loadView()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLoad() {
        
    }
    
    deinit {
        
    }

    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        handler(nil)
    }
     */
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        urlSchemeTask.didReceive(
            HTTPURLResponse(url: urlSchemeTask.request.url!,
                            mimeType: "application/octet-stream",
                            expectedContentLength: try! urlSchemeTask.request.url!.resourceValues(forKeys: [.fileSizeKey]).fileSize!,
                            textEncodingName: nil)
        )
        urlSchemeTask.didFinish()
    }
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        print("stop \(urlSchemeTask)")
    }
    
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        print("open panel!")
//        completionHandler([URL(fileURLWithPath: "/Users/work/Documents/bags/remapped_turtle.bag")])
        completionHandler([Bundle(for: Self.self).url(forResource: "remapped_turtle", withExtension: "bag")!])
    }
    
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failed: \(navigation) \(error)")
    }
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        url.startAccessingSecurityScopedResource()
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
//        webView.configuration.preferences.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        webView.configuration.setURLSchemeHandler(self, forURLScheme: "x-test-bag")
//        webView.configuration.userContentController.addUserScript(
//            WKUserScript(source: "window.loadBag(\(String(data: try! JSONSerialization.data(withJSONObject: url.absoluteString, options: .fragmentsAllowed), encoding: .utf8)!))", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
//        webView.loadFileURL(Bundle(for: Self.self).url(forResource: "foo", withExtension: "html")!, allowingReadAccessTo: url)
        webView.load(URLRequest(url: URL(string: "http://localhost:11122/foo.html")!))
        
        
        handler(nil)
//        return;
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
//            self.webView.mouseDown(with: NSEvent.mouseEvent(with: .leftMouseDown, location: NSPoint(x: 705, y: 466), modifierFlags: [], timestamp: CACurrentMediaTime(), windowNumber: self.webView.window!.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 0)!)
            let event = NSEvent.mouseEvent(with: .leftMouseDown, location: NSPoint(x: 40, y: self.webView.frame.height - 37), modifierFlags: [], timestamp: CACurrentMediaTime(), windowNumber: self.webView.window!.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 0)!
            
            self.webView.mouseDown(with: event)
            self.webView.mouseUp(with: NSEvent.mouseEvent(with: .leftMouseUp, location: NSPoint(x: 40, y: self.webView.frame.height - 37), modifierFlags: [], timestamp: CACurrentMediaTime(), windowNumber: self.webView.window!.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 0)!)
            return
//            let event = NSEvent.otherEvent(with: .leftMouseDragged, location: NSPoint.zero, modifierFlags: [], timestamp: CACurrentMediaTime(), windowNumber: self.webView.window!.windowNumber, context: nil, subtype: 0, data1: 0, data2: 0)!
            let item = NSDraggingItem(pasteboardWriter:
                                        Bundle(for: Self.self).url(forResource: "remapped_turtle", withExtension: "bag")! as NSURL
//                NSURL(fileURLWithPath: "/Users/work/Documents/bags/remapped_turtle.bag")
            )
            item.draggingFrame = NSRect(x: 0, y: 0, width: 100, height: 100)
            
//            pboard.setPropertyList(NSURL(fileURLWithPath: "/Users/work/Documents/bags/remapped_turtle.bag"), forType: .fileURL)
            pboard.setString((Bundle(for: Self.self).url(forResource: "remapped_turtle", withExtension: "bag")! as NSURL).absoluteString!, forType: .fileURL)
            self.webView.beginDraggingSession(with: [item], event: event, source: self)
            
            class DragInfo: NSObject, NSDraggingInfo {
                var draggingDestinationWindow: NSWindow? = nil
                
                var draggingSourceOperationMask: NSDragOperation = .copy
                
                var _draggingLocation: NSPoint = .zero
                var draggingLocation: NSPoint {
                    return _draggingLocation
                }
                
                var draggedImageLocation: NSPoint = .zero
                
                var draggedImage: NSImage? = nil
                
                var draggingPasteboard: NSPasteboard = pboard
                
                var draggingSource: Any? = nil
                
                var draggingSequenceNumber: Int = 0
                
                func slideDraggedImage(to screenPoint: NSPoint) {
                    print("Slide dragged image")
                }
                
                override func namesOfPromisedFilesDropped(atDestination dropDestination: URL) -> [String]? {
                    print("Names of files", dropDestination)
                    return nil
                }
                
                var draggingFormation: NSDraggingFormation = .none
                
                var animatesToDestination: Bool = false
                
                var numberOfValidItemsForDrop: Int = 1
                
                func enumerateDraggingItems(options enumOpts: NSDraggingItemEnumerationOptions = [], for view: NSView?, classes classArray: [AnyClass], searchOptions: [NSPasteboard.ReadingOptionKey : Any] = [:], using block: @escaping (NSDraggingItem, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
                    
                }
                
                var springLoadingHighlight: NSSpringLoadingHighlight = .none
                
                func resetSpringLoading() {
                    
                }
                
            }
            
            let dragInfo = DragInfo()
            
            dragInfo.draggingSource = self
            dragInfo.draggingDestinationWindow = self.webView.window
            dragInfo._draggingLocation = self.webView.convert(.zero, to: nil)
//            dragInfo._draggingLocation = NSPoint(x: 100, y: 100)
            print("Set loc: \(dragInfo._draggingLocation)")
            let op = self.webView.draggingEntered(dragInfo)
            print("entered op: \(op)")
            let ret = self.webView.prepareForDragOperation(dragInfo)
            print("prepare: \(ret)")
            
            self.webView.mouseEntered(with: NSEvent.mouseEvent(with: .mouseMoved, location: NSPoint(x: 100, y: 100), modifierFlags: [], timestamp: CACurrentMediaTime(), windowNumber: self.webView.window!.windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0)!)
            self.webView.mouseMoved(with: NSEvent.mouseEvent(with: .mouseMoved, location: NSPoint(x: 100, y: 100), modifierFlags: [], timestamp: CACurrentMediaTime(), windowNumber: self.webView.window!.windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0)!)
            self.webView.mouseDragged(with: NSEvent.mouseEvent(with: .mouseMoved, location: NSPoint(x: 100, y: 100), modifierFlags: [], timestamp: CACurrentMediaTime(), windowNumber: self.webView.window!.windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0)!)
//            self.webView.mouseUp(with: NSEvent.mouseEvent(with: .leftMouseUp, location: NSPoint(x: 100, y: 100), modifierFlags: [], timestamp: CACurrentMediaTime(), windowNumber: self.webView.window!.windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0)!)
            
            self.webView.performDragOperation(dragInfo)
            self.webView.concludeDragOperation(dragInfo)
            
            url.stopAccessingSecurityScopedResource()
        }

//        webView.loadFileURL(<#T##URL: URL##URL#>, allowingReadAccessTo: url)
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.
        
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        print("Source operation mask")
        return .copy
    }
}
