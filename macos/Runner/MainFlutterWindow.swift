import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    self.contentViewController = flutterViewController
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // 💡 Maximize window on startup
    self.zoom(self)
  }
}
