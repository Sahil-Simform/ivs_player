import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ivs_player/mod.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  IvsController? controller;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) async {
      final controller = await IvsController.create();
      controller.state.addListener(_rebuild);
      setState(() {
        this.controller = controller;
      });
    });
  }

  void togglePlay() {
    if (controller?.state.value == PlayerState.playing) {
      controller?.pause();
    } else {
      controller?.play();
    }
  }

  @override
  void deactivate() {
    controller?.state.removeListener(_rebuild);
    super.deactivate();
  }

  void _rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;

    return MaterialApp(
      home: Scaffold(
          body: Stack(children: [
            if (controller != null)
              Center(child: IvsPlayer(controller: controller)),
            Align(
              alignment: Alignment.topCenter,
              child: UrlBar(controller: controller),
            ),
            if (controller?.state == PlayerState.buffering)
              Center(child: CircularProgressIndicator()),
          ]),
          floatingActionButton: FloatingActionButton(
            child: controller?.state.value == PlayerState.playing
                ? Icon(Icons.pause)
                : Icon(Icons.play_arrow),
            onPressed: togglePlay,
          )),
    );
  }
}

class UrlBar extends StatefulWidget {
  const UrlBar({Key? key, required this.controller}) : super(key: key);

  final IvsController? controller;

  @override
  State<UrlBar> createState() => _UrlBarState();
}

class _UrlBarState extends State<UrlBar> {
  bool isAddressVisible = true;
  TextEditingController urlController = TextEditingController();
  StreamSubscription? _subscription;
  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>? banner;

  @override
  void initState() {
    super.initState();
    loadUrl();
    subscribe(widget.controller);

    SchedulerBinding.instance!.addPostFrameCallback((_) {
      toggle();
    });
  }

  @override
  void didUpdateWidget(UrlBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      unsubscribe(oldWidget.controller);
      subscribe(widget.controller);
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  void toggle() {
    if (banner == null) {
      open();
    } else {
      close();
    }
  }

  void open() {
    final banner =
        ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
            content: SafeArea(
              child: Container(
                color: Colors.white,
                height: 60,
                child: TextField(
                  style: TextStyle(fontSize: 20),
                  controller: urlController,
                ),
              ),
            ),
            actions: [
          SafeArea(
            child: ElevatedButton(
              onPressed: saveAndLoadUrl,
              child: Text("Open"),
            ),
          ),
        ]));
    setState(() {
      this.banner = banner;
    });
  }

  void close() {
    setState(() {
      banner?.close();
      banner = null;
    });
  }

  Future<void> loadUrl() async {
    final preferences = await SharedPreferences.getInstance();
    final url = await preferences.getString('url');
    if (url != null) {
      urlController.text = url;
      widget.controller?.load(url);
    }
  }

  void subscribe(IvsController? controller) {
    if (controller == null) {
      return;
    }

    controller.duration.addListener(_showDuration);
    _subscription = controller.eventStream.listen(_showError);
  }

  void unsubscribe(IvsController? controller) {
    if (controller == null) {
      return;
    }

    controller.duration.removeListener(_showDuration);
    _subscription?.cancel();
    _subscription = null;
  }

  void _showDuration() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("duration: ${widget.controller?.duration.value}")));
  }

  void _showError(dynamic event) {
    if (event is Failed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: ${event.error}")));
    }
  }

  saveAndLoadUrl() async {
    final uri = Uri.parse(urlController.text);
    final preferences = await SharedPreferences.getInstance();
    preferences.setString('url', '$uri');

    close();

    await widget.controller?.load('$uri');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: SizedBox(
            height: banner == null ? 60 : double.infinity,
            width: double.infinity,
          )),
    );
  }
}
