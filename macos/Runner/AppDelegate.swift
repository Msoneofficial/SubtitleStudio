import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    var scopedUrl: [URL] = []

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let bookmarkChannel = FlutterMethodChannel(name: "com.msone.subeditor/bookmark",
                                                   binaryMessenger: controller.engine.binaryMessenger)
        bookmarkChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "createBookmark":
                self.createBookmark(call: call, result: result)
            case "resolveBookmark":
                self.resolveBookmark(call: call, result: result)
            case "stopAccessingSecurityScopedResource":
                self.stopAccessingSecurityScopedResource(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
    }

    private func stopAccessingSecurityScopedResource(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "File path is required.", details: nil))
            return
        }

        let url = URL(fileURLWithPath: filePath)
        url.stopAccessingSecurityScopedResource()
        scopedUrl.removeAll { $0 == url }
        result(nil)
    }

    private func createBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "File path is required.", details: nil))
            return
        }

        let url = URL(fileURLWithPath: filePath)
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            result(FlutterStandardTypedData(bytes: bookmarkData))
        } catch {
            result(FlutterError(code: "CREATE_BOOKMARK_FAILED", message: "Failed to create bookmark: \(error.localizedDescription)", details: nil))
        }
    }

    private func resolveBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bookmarkData = (args["bookmark"] as? FlutterStandardTypedData)?.data else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Bookmark data is required.", details: nil))
            return
        }

        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)

            if isStale {
                // Handle stale bookmark data, e.g., by creating a new one.
                // For now, we'll just log it.
                print("Bookmark data is stale.")
            }

            if url.startAccessingSecurityScopedResource() {
                scopedUrl.append(url)
                result(url.path)
            } else {
                result(FlutterError(code: "ACCESS_DENIED", message: "Failed to access security-scoped resource.", details: nil))
            }
        } catch {
            result(FlutterError(code: "RESOLVE_BOOKMARK_FAILED", message: "Failed to resolve bookmark: \(error.localizedDescription)", details: nil))
        }
    }

    override func applicationWillTerminate(_ aNotification: Notification) {
        for url in scopedUrl {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
