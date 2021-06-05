import Foundation

struct Configuration {
  enum LoadingStrategy: String {
    case navigationComplete
    case waitForSignal
  }

  var loadingStrategy: LoadingStrategy
  var pageURL: URL
  var preferredContentSize: NSSize?
}

extension Configuration {
  static func fromMainBundle() throws -> Configuration {
    guard let dict = (Bundle.main.localizedInfoDictionary ?? Bundle.main.infoDictionary)?["QLJS"] as? [String: Any] else {
      throw GenericError(message: "Could not read QLJS configuration from Info.plist")
    }

    let preferredContentSize = (dict["preferredContentSize"] as? String).map(NSSizeFromString)

    guard let pagePath = dict["pagePath"] as? String else {
      throw GenericError(message: "Missing pagePath in QLJS configuration")
    }
    guard let resourceURL = Bundle.main.resourceURL else {
      throw GenericError(message: "Bundle has no resource URL")
    }
    guard let pageURL = URL(string: pagePath, relativeTo: resourceURL) else {
      throw GenericError(message: "Unable to construct full page URL relative to \(resourceURL)")
    }
    guard (try? pageURL.checkResourceIsReachable()) == true else {
      throw GenericError(message: "File does not exist at “\(pageURL)”")
    }

    guard let loadingStrategy = dict["loadingStrategy"] as? String else {
      throw GenericError(message: "Missing loadingStrategy in QLJS configuration")
    }
    guard let loadingStrategy = Configuration.LoadingStrategy(rawValue: loadingStrategy) else {
      throw GenericError(message: "Invalid loadingStrategy “\(loadingStrategy)” in QLJS configuration")
    }

    return Configuration(
      loadingStrategy: loadingStrategy,
      pageURL: pageURL,
      preferredContentSize: preferredContentSize)
  }
}
