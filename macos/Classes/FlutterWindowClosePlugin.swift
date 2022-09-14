import Cocoa
import FlutterMacOS

public class FlutterWindowClosePlugin: NSObject, FlutterPlugin, NSWindowDelegate {
    var window: NSWindow?
    var notificationChannel: FlutterMethodChannel?
    var eventChannel: FlutterEventChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_window_close", binaryMessenger: registrar.messenger)
        let instance = FlutterWindowClosePlugin()
        instance.notificationChannel = FlutterMethodChannel(name: "flutter_window_close_notification", binaryMessenger: registrar.messenger)
        instance.window = NSApp.windows.first
        instance.window?.delegate = instance
        instance.applicationDidFinishLaunching2()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "closeWindow":
            self.window?.performClose(nil)
            result(nil)
        case "destroyWindow":
            self.window?.close()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        notificationChannel?.invokeMethod("onWindowClose", arguments: nil)
        return false
    }



    public func applicationDidFinishLaunching2() {

          NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),
                                                            name: NSWorkspace.willSleepNotification, object: nil)
          NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),
                                                            name: NSWorkspace.didWakeNotification, object: nil)

      }


      @objc public func sleepListener(_ aNotification: Notification) {
          
          if aNotification.name == NSWorkspace.willSleepNotification {
              notificationChannel?.invokeMethod("onWindowsSleep", arguments: "sleep")
              NSLog("Going to sleep")
          } else if aNotification.name == NSWorkspace.didWakeNotification {
               notificationChannel?.invokeMethod("onWindowsSleep", arguments: "woke_up")
              NSLog("Woke up")
          }else {
              NSLog("Some other event other than the first two")
          }
      }
}
