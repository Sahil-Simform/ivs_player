import Flutter
import UIKit
import AmazonIVSPlayer


public class SwiftIvsPlayerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ivs_player", binaryMessenger: registrar.messenger())
    let instance = SwiftIvsPlayerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    let factory = IvsViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "ivs_player")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
