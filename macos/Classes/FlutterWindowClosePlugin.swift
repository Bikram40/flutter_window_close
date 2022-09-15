import Cocoa
import FlutterMacOS

public class FlutterWindowClosePlugin: NSObject, FlutterPlugin, NSWindowDelegate, NSApplicationDelegate {
    var window: NSWindow?
    var notificationChannel: FlutterMethodChannel?
    var eventChannel: FlutterEventChannel?

//       @IBOutlet var window: NSWindow!

      public var logoutTaskLaunched = false

//       public func launchLogoutTask() {
//           assert(!logoutTaskLaunched, "Logout task was already launched")
//
//           let task = Process()
//           task.executableURL = URL(fileURLWithPath: "/bin/sleep")
//           task.arguments = ["5"]
//           task.terminationHandler = { task in
//               if task.terminationStatus == 0 {
//                    NSLog("Logout task - success")
//                   DispatchQueue.main.async {
//                       NSApp.reply(toApplicationShouldTerminate: true)
//                   }
//               } else {
//                    NSLog("Logout task - failed")
//                   DispatchQueue.main.async { [weak self] in
//                       NSApp.reply(toApplicationShouldTerminate: false)
//                       self?.logoutTaskLaunched = false
//                   }
//               }
//           }
//           do {
//               try task.run()
//               logoutTaskLaunched = true
//                NSLog("Logout task - Sleeping for 5s")
//           }
//           catch {
//                NSLog("Logout task - failed to launch task: \(error)")
//               NSApp.reply(toApplicationShouldTerminate: false)
//           }
//       }

       public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
          let reason = NSAppleEventManager.shared()
              .currentAppleEvent?
              .attributeDescriptor(forKeyword: kAEQuitReason)

          switch reason?.enumCodeValue {
          case kAELogOut, kAEReallyLogOut:
               NSLog("Logout")
              if !logoutTaskLaunched {
//                   launchLogoutTask()
              }
              return .terminateLater

          case kAERestart, kAEShowRestartDialog:
               NSLog("Restart")
              return .terminateNow

          case kAEShutDown, kAEShowShutdownDialog:
               NSLog("Shutdown")
              return .terminateNow

          case 0:
              // `enumCodeValue` docs:
              //
              //    The contents of the descriptor, as an enumeration type,
              //    or 0 if an error occurs.
               NSLog("We don't know")
              return .terminateNow

          default:
               NSLog("Cmd-Q, Quit menu item, ...")
              return .terminateLater
          }
      }
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
 NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),
                                                            name: NSWorkspace.willPowerOffNotification, object: nil)
 NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)),
                                                            name: NSWorkspace.didTerminateApplicationNotification, object: nil)


   }


      @objc public func sleepListener(_ aNotification: Notification) {
          
          if aNotification.name == NSWorkspace.willSleepNotification {
              notificationChannel?.invokeMethod("onWindowsSleep", arguments: "sleep")
              NSLog("Going to sleep")
          } else if aNotification.name == NSWorkspace.didWakeNotification {
               notificationChannel?.invokeMethod("onWindowsSleep", arguments: "woke_up")
              NSLog("Woke up")
          }else if aNotification.name == NSWorkspace.willPowerOffNotification {
               notificationChannel?.invokeMethod("onWindowsSleep", arguments: "power_off")
             NSLog("power off")
          }else if aNotification.name == NSWorkspace.didTerminateApplicationNotification {
                          notificationChannel?.invokeMethod("onWindowsSleep", arguments: "terminate_app")
                         NSLog("terminate_app")
                     } else {
              NSLog("Some other event other than the first two")
          }
      }
}
