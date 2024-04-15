// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

declare namespace quicklook {
  /**
   * Get a JavaScript File object referencing the file being previewed.
   */
  function getPreviewedFile(): Promise<{
    /**
     * A reference to the previewed file which can be used to read its contents. File inherits from
     * [Blob](https://developer.mozilla.org/en-US/docs/Web/API/Blob), so you can use Blob APIs like
     * `text()` or `arrayBuffer()` to read the file.
     */
    file: File;
    /** The absolute path to the previewed file. */
    path: string
  }>;

  /**
   * Inform Quick Look that the page has finished loading and the preview should be displayed. Until
   * this function is called, the system will display a loading spinner.
   *
   * Has an effect only if `loadingStrategy` was set to `waitForSignal` in the QLJS configuration.
   */
  function finishedLoading(): Promise<void>;
}
