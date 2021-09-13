import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class IvsEvent {}

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

class QualityChanged extends IvsEvent {}

class Rebuffer extends IvsEvent {}

class NetworkBecameUnavailable extends IvsEvent {}

class IvsController {
  final int id;
  final MethodChannel _channel;
  final EventChannel _eventChannel;
  Stream get eventStream {
    final transformer =
        StreamTransformer.fromHandlers(handleData: _transformData);
    return _eventChannel.receiveBroadcastStream().transform(transformer);
  }

  final state = ValueNotifier<IvsState>(IvsState.idle);
  final position = ValueNotifier<Duration>(Duration.zero);
  final duration = ValueNotifier<Duration>(Duration.zero);

  IvsController({required this.id})
      : _channel = MethodChannel("ivs_player:$id"),
        _eventChannel = EventChannel("ivs_event:$id") {
    // final channel = EventChannel("ivs_event:$id");
    // eventStream = channel.receiveBroadcastStream().transform(transformer);
    // _consume(eventStream);
    // eventStream.drain();
  }

  Future<void> _consume(Stream stream) async {
    await for (final value in stream) {}
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
    print(data);
    final type = data?['type'];
    switch (type) {
      case 'duration_changed':
        duration.value = Duration(milliseconds: data['duration']);
        break;
      case 'fail':
        sink.add(Failed(data['error']));
        break;
      case 'state_changed':
        final value = IvsState.values
            .firstWhere((element) => describeEnum(element) == data['state']);
        state.value = value;
        break;
      case 'sought_to':
        position.value = Duration(milliseconds: data['position']);
        break;
      case 'rebuffer':
        sink.add(Rebuffer());
        break;
      case 'network_became_unavailable':
        sink.add(NetworkBecameUnavailable());
        break;
      case 'quality_changed':
        sink.add(QualityChanged());
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
