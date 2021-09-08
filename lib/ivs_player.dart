import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class IvsController {
  final int id;
  final MethodChannel _channel;
  final EventChannel _eventChannel;

  IvsController({required this.id})
      : _channel = MethodChannel("ivs_player:$id"),
        _eventChannel = EventChannel("ivs_event:$id");

  Future<void> load(String src) async {
    return _channel.invokeMethod('load', {"src": src});
  }

  Future<void> play() async {
    return _channel.invokeMethod('play');
  }

  Future<void> pause() async {
    return _channel.invokeMethod('pause');
  }

  Future<int> seekTo(int millisecond) async {
    return await _channel.invokeMethod('seek_to', millisecond);
  }

  Future<int> getDuration() async {
    return await _channel.invokeMethod('get_duration');
  }

  Stream<dynamic> stream() {
    return _eventChannel.receiveBroadcastStream();
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

    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory:
          (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
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
  }
}
