# quicklookjs

[![npm version](https://img.shields.io/npm/v/quicklookjs)](https://www.npmjs.com/package/quicklookjs)

<img align="right" alt="quicklookjs demo" src="https://user-images.githubusercontent.com/14237/121449575-cb86f080-c935-11eb-9a45-b5837d517616.gif">

quicklookjs provides a macOS [Quick Look](https://developer.apple.com/documentation/quicklook) Previewing extension that displays a web page. By packaging this preview extension with your native app, and replacing the web page with your own, you can implement a Quick Look preview experience using HTML/JavaScript (or a web framework of your choice).

## 📝 Create a preview page

The first step to creating a Quick Look preview is to write the preview page! You can see an example preview page, included with quicklookjs, at [preview.html](PreviewExtension/preview.html).

JavaScript in a quicklookjs preview page can use two functions on the global `quicklook` object, `getPreviewedFile` and `finishedLoading`, to implement previews:

```html
<script>
  // We're using an async function so we can more easily interact with Promises returned by quicklookjs.
  // This isn't required; you can always use .then() instead of await.
  async function main() {
    // Step 1: get the file that we're supposed to show a preview for.
    // `file` is a File object, the same as if the user had dragged & dropped the file into your page.
    const { file, path } = await quicklook.getPreviewedFile();

    // Step 2: ...do anything you'd like in order to create a preview of the file!
    // File inherits from Blob (https://developer.mozilla.org/en-US/docs/Web/API/Blob), so you can
    // use Blob APIs like `text()` or `arrayBuffer()` to read the file.

    // Step 3: tell quicklookjs that we're ready to display the preview.
    await quicklook.finishedLoading();
  }

  main();
</script>
```

Other than these two functions, the preview implementation is totally up to you. Get creative! 🎨

## 📦 Add the preview extension to your app

To make your preview page available to macOS, it needs to be bundled inside the App Extension provided by quicklookjs.

1. Install this package.

   ```sh
   npm install --save-dev quicklookjs
   ```

1. When packaging your app, **copy the `.appex` bundle** into your application at `.../Contents/PlugIns`:

   ```sh
   mkdir -p MyApp.app/Contents/PlugIns

   cp -R node_modules/quicklookjs/dist/PreviewExtension.appex MyApp.app/Contents/PlugIns/PreviewExtension.appex
   ```

   If you're using electron-builder to package your app, you can do this by adding an [`extraFiles`](https://www.electron.build/configuration/contents#extrafiles) entry to your builder configuration:

   ```json
   "extraFiles": [
     {
       "from": "node_modules/quicklookjs/dist/PreviewExtension.appex",
       "to": "PlugIns/PreviewExtension.appex"
     }
   ],
   ```

   You might also want to perform the following steps as part of an [`afterPack`](https://www.electron.build/configuration/configuration#afterpack) script.

1. **Edit the extension's Info.plist** to suit your app:

   - The extension's CFBundleIdentifier **should be prefixed with the containing app's CFBundleIdentifier**. For example, if the app bundle ID is `com.example.MyApp`, the extension's bundle ID could be `com.example.MyApp.PreviewExtension`.

   - Update the `NSExtension.NSExtensionAttributes.QLSupportedContentTypes` with an array of the **file content types you support**. These can match the [system-declared UTIs](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html#//apple_ref/doc/uid/TP40009259-SW1), or if your app declares custom types, these should match the `UTTypeIdentifier` entries in your app's Info.plist. (See [Declaring New Uniform Type Identifiers](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_declare/understand_utis_declare.html) for more info about custom file types.)

   - Optionally customize the configuration dictionary under the `QLJS` key (more about this [below](#-configuration)).

1. **Copy your preview page into the extension bundle.** By default the extension will load the page at `PreviewExtension.appex/Contents/Resources/preview.html` which is pre-configured for you with an example page. The file name loaded by the extension is [configurable](#-configuration).

1. **Re-codesign the extension.** This step is important because the modifications you made to the bundle render the existing signature invalid, and macOS requires Quick Look extensions to be signed/sandboxed. An [entitlements plist file](https://developer.apple.com/documentation/security/app_sandbox) is included with the quicklookjs package to get you started.

   ```sh
   codesign \
     --sign - \
     --force \
     --entitlements node_modules/quicklookjs/dist/PreviewExtension.entitlements \
     MyApp.app/Contents/PlugIns/PreviewExtension.appex
   ```

Now your app has Quick Look support! 🎉

## 🛠 Configuration

You can customize some of the preview extension's behaviors by editing the `QLJS` dictionary in its Info.plist. The currently supported keys are:

- **`loadingStrategy`** (required): one of two pre-defined string values:

  - `waitForSignal`: show the preview page only once it signals that it's ready via `quicklook.finishedLoading()`. This is the preferred loading strategy.
  - `navigationComplete`: show the preview page as soon as it loads in the web view.

- **`pagePath`** (required): the path to the HTML page that will be displayed as the preview, relative to `PreviewExtension.appex/Contents/Resources`. In the example Info.plist this is `preview.html`.

- **`preferredContentSize`** (optional): a string specifying the size of the preview window. In the example Info.plist this is `{500,300}`.

## 🧠 Behind the scenes

Under the hood, quicklookjs loads your preview page in a [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview), and the `quicklook` functions are provided in a user script.

In order to give your JavaScript code access to the previewed file as a File object, when you call `getPreviewedFile()`, quicklookjs temporarily adds an `<input type="file">` to the page, and sends a fake click event to the web view. This allows the native code to [respond with a file URL](https://developer.apple.com/documentation/webkit/wkuidelegate/1641952-webview), which the web view translates into a File object.
