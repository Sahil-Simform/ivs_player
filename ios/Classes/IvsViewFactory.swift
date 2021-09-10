import Flutter
import UIKit
import AmazonIVSPlayer

class IvsViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return PlatformIvsView(
            viewIdentifier: viewId,
            binaryMessenger: messenger)
    }
}

class IvsEventSink: NSObject, FlutterStreamHandler, IVSPlayer.Delegate {
    private var sink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
    
    func player(_ player: IVSPlayer, didChangeDuration duration: CMTime) {
        post(["type": "duration_changed", "duration": duration.epoch])
    }
    
    func player(_ player: IVSPlayer, didFailWithError error: Error) {
        post(["type": "fail", "error": "\(error)"])
    }
    
    func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
        let code = stateToString(state)
        post(["type": "state_changed", "state": code])
    }
    
    func player(_ player: IVSPlayer, didSeekTo time: CMTime) {
        post(["type": "sought_to", "position": time.epoch])
    }
    
    func playerWillRebuffer(_ player: IVSPlayer) {
        post(["type": "will_rebuffer"])
    }
    
    func playerNetworkDidBecomeUnavailable(_ player: IVSPlayer) {
        post(["type": "network_became_unavailable"])
    }
    
    func post(_ obj: Any?) {
        sink?(obj)
    }
    
    private func stateToString(_ state: IVSPlayer.State) -> String {
        switch state {
        case .idle:
            return "idle";
        case .buffering:
            return "buffering";
        case .ready:
            return "ready";
        case .playing:
            return "playing";
        case .ended:
            return "ended";
        default:
            return "";
        };
    }
}

class PlatformIvsView: NSObject, FlutterPlatformView {
    private var _playerView = IVSPlayerView()
    private var _player = IVSPlayer()
    private var _methodChannel: FlutterMethodChannel;
    private var _eventChannel: FlutterEventChannel;
    private var _eventSink: IvsEventSink;
    
    init(
        viewIdentifier viewId: Int64,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _methodChannel = FlutterMethodChannel(
            name: String(format: "ivs_player:%d", viewId),
            binaryMessenger: messenger)
        _eventChannel = FlutterEventChannel(
            name: String(format: "ivs_event:%d", viewId),
            binaryMessenger: messenger)
        _eventSink = IvsEventSink()
        super.init()
        
        _methodChannel.setMethodCallHandler(handleMethodCall)
        _eventChannel.setStreamHandler(_eventSink)
        
        _player.delegate = _eventSink
        _playerView.player = _player
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    func view() -> UIView {
        return _playerView
    }
    
    func handleMethodCall(_ call: FlutterMethodCall, _ result: FlutterResult) -> Void {
        switch call.method {
        case "load":
            let arguments = call.arguments as! [String: String]
            let url = URL(string: arguments["src"]!)
            _player.load(url)
            
            do {
                let audio = AVAudioSession.sharedInstance()
                try audio.setCategory(.playback)
                try audio.setActive(true)
            } catch {
                result(FlutterError(code: "audio_failure", message: "\(error)", details: "\(error)" ))
                return;
            }
            
            result(nil)
        case "play":
            _player.play()
            _player.muted = false
            _player.volume = 1
            result(nil)
        case "pause":
            _player.pause()
            result(nil)
        case "seek_to":
            let milliseconds = call.arguments as! Int64
            _player.seek(to: CMTime(value: milliseconds, timescale: CMTimeScale(1000)))
            result(nil)
        case "get_duration":
            result(_player.duration)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // iOS 10 devices may experience a crash when returning from background.
    // https://docs.aws.amazon.com/ivs/latest/userguide/player-ios.html
    @objc func applicationDidEnterBackground(_ notification: NSNotification) {
        _player.pause()
    }
    
    func dispose() {
        _methodChannel.setMethodCallHandler(nil)
        _eventSink.post(FlutterEndOfEventStream)
        _eventChannel.setStreamHandler(nil)
    }
}
