// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

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
  /// Used during `ScriptMessage.getPreviewedFile` to signal that the page is ready to accept a fake click event in
  /// order to trigger the file input.
  case clickFileInput

  case error(String)

  enum Actions: String, Codable {
    case clickFileInput
    case error
  }

  enum CodingKeys: CodingKey {
    case action
    case message
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    switch try container.decode(Actions.self, forKey: .action) {
    case .clickFileInput: self = .clickFileInput
    case .error: self = try .error(container.decode(String.self, forKey: .message))
    }
  }
}
