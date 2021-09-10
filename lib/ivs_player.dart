import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class IvsEvent {}

class DurationChanged extends IvsEvent {
  final Duration duration;

  DurationChanged(this.duration);
}

class Failed extends IvsEvent {
  final String error;

  Failed(this.error);
}

enum IvsState {
  idle,
  ready,
  buffering,
  playing,
  ended,
}

class StateChanged extends IvsEvent {
  final IvsState state;

  StateChanged(this.state);

  @override
  String toString() {
    return 'StateChanged(state: $state)';
  }
}

class SoughtTo extends IvsEvent {
  final Duration position;

  SoughtTo(this.position);
}

class WillRebuffer extends IvsEvent {}

class NetworkBecameUnavailable extends IvsEvent {}

class IvsController {
  final int id;
  final MethodChannel _channel;
  late final Stream eventStream;

  IvsState get state => _state;
  IvsState _state = IvsState.idle;

  IvsController({required this.id})
      : _channel = MethodChannel("ivs_player:$id") {
    final channel = EventChannel("ivs_event:$id");
    final transformer =
        StreamTransformer.fromHandlers(handleData: _transformData);
    eventStream = channel.receiveBroadcastStream().transform(transformer);
    eventStream.drain();
  }

  Future<void> load(String src) {
    return _channel.invokeMethod('load', {"src": src});
  }

  Future<void> play() {
    return _channel.invokeMethod('play');
  }

  Future<void> pause() {
    return _channel.invokeMethod('pause');
  }

  Future<int> seekTo(int millisecond) async {
    return await _channel.invokeMethod('seek_to', millisecond);
  }

  Future<int> getDuration() async {
    return await _channel.invokeMethod('get_duration');
  }

  void _transformData(data, EventSink sink) {
    final type = data?['type'];
    switch (type) {
      case 'duration_changed':
        sink.add(DurationChanged(Duration(milliseconds: data['duration'])));
        break;
      case 'fail':
        sink.add(Failed(data['error']));
        break;
      case 'state_changed':
        final value = IvsState.values
            .firstWhere((element) => describeEnum(element) == data['state']);
        _state = value;
        sink.add(StateChanged(value));
        break;
      case 'sought_to':
        sink.add(SoughtTo(Duration(milliseconds: data['position'])));
        break;
      case 'will_rebuffer':
        sink.add(WillRebuffer());
        break;
      case 'network_became_unavailable':
        sink.add(NetworkBecameUnavailable());
        break;
      default:
        sink.addError('Unknown event type: $type');
    }
  }
}

class IvsPlayer extends StatefulWidget {
  final String? src;
  final void Function(IvsController)? onControllerCreated;

  const IvsPlayer({Key? key, this.src, this.onControllerCreated})
      : super(key: key);

  @override
  _IvsPlayerState createState() => _IvsPlayerState();
}

class _IvsPlayerState extends State<IvsPlayer> {
  IvsController? controller;

  @override
  void didUpdateWidget(IvsPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final src = widget.src;
    if (src != null && oldWidget.src != src) {
      controller?.load(src);
    }
  }

  void createController(int id) async {
    final controller = IvsController(id: id);
    final src = widget.src;
    this.controller = controller;
    widget.onControllerCreated?.call(controller);

    if (src != null) {
      await controller.load(src);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'ivs_player';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformViewLink(
          viewType: viewType,
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const <
                  Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..addOnPlatformViewCreatedListener(createController)
              ..create();
          },
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: creationParams,
          onPlatformViewCreated: createController,
        );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the plugin');
    }
  }
}
