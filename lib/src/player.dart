import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ivs_player/src/controller.dart';

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
    const viewType = 'ivs_player';
    final creationParams = <String, dynamic>{};

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
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: createController,
        );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the plugin');
    }
  }
}
