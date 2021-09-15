import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:ivs_player/src/controller.dart';

class IvsPlayer extends StatefulWidget {
  final IvsController controller;

  const IvsPlayer({Key? key, required this.controller}) : super(key: key);

  @override
  _IvsPlayerState createState() => _IvsPlayerState();
}

class _IvsPlayerState extends State<IvsPlayer> {
  static const String _viewType = 'ivs_player';

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) async {
      final controller = await IvsController.create();
      controller.quality.addListener(_rebuild);
    });
  }

  @override
  void dispose() {
    widget.controller.quality.removeListener(_rebuild);
    widget.controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    setState(() {});
  }

  Widget _buildTexture() {
    final quality = widget.controller.quality.value;
    if (quality.height == 0) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: quality.width / quality.height,
      child: Texture(textureId: widget.controller.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildTexture();
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _viewType,
          creationParams: <String, dynamic>{'id': widget.controller.id},
          creationParamsCodec: const StandardMessageCodec(),
          // onPlatformViewCreated: _createController,
        );
      default:
        return Text(
            '$defaultTargetPlatform is not yet supported by the plugin');
    }
  }
}
