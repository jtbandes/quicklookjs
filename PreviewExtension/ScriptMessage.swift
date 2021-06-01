import Foundation

enum ScriptMessage: Decodable {
  /// Get a JavaScript File object referencing the file being previewed.
  case getPreviewedFile

  /// Inform Quick Look that the page has finished loading and the preview should be displayed.
  /// Has an effect only if `configuration.loadingStrategy` was set to `waitForSignal`.
  case finishedLoading

  enum Actions: String, Codable {
    case finishedLoading
    case getPreviewedFile
  }

  enum CodingKeys: CodingKey {
    case action
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Actions.self, forKey: .action) {
    case .finishedLoading: self = .finishedLoading
    case .getPreviewedFile: self = .getPreviewedFile
    }
  }
}

enum InternalScriptMessage: Decodable {
  /// Used during `ScriptMessage.getPreviewedFile` to signal that the page is ready to accept a fake click event in order to trigger the file input.
  case clickFileInput

  enum Actions: String, Codable {
    case clickFileInput
  }

  enum CodingKeys: CodingKey {
    case action
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Actions.self, forKey: .action) {
    case .clickFileInput: self = .clickFileInput
    }
  }
}
