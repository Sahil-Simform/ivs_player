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
  static const String _viewType = 'ivs_player';

  final GlobalKey _androidKey = GlobalKey();
  IvsController? controller;

  @override
  void didUpdateWidget(IvsPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final src = widget.src;
    if (src != null && oldWidget.src != src) {
      controller?.load(src);
    }
  }

  @override
  void dispose() {
    controller?.quality.removeListener(_rebuild);
    super.dispose();
  }

  void _createController(int id) async {
    final controller = IvsController(id: id);
    final src = widget.src;
    this.controller = controller;
    controller.quality.addListener(_rebuild);
    widget.onControllerCreated?.call(controller);

    if (src != null) {
      await controller.load(src);
    }
  }

  void _rebuild() {
    setState(() {});
  }

  PlatformViewLink _buildAndroidPlatformView(
      Map<String, dynamic> creationParams) {
    return PlatformViewLink(
      key: _androidKey,
      viewType: _viewType,
      surfaceFactory: (
        BuildContext context,
        PlatformViewController controller,
      ) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener(_createController)
          ..create();
      },
    );
  }

  Widget _buildAndroidView(Map<String, dynamic> creationParams) {
    final quality = controller?.quality.value;
    if (quality == null || quality.height == 0) {
      return _buildAndroidPlatformView(creationParams);
    }

    return AspectRatio(
      aspectRatio: quality.width / quality.height,
      child: _buildAndroidPlatformView(creationParams),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creationParams = <String, dynamic>{};

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildAndroidView(creationParams);
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _viewType,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _createController,
        );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the plugin');
    }
  }
}
