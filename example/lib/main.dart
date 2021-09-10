import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ivs_player/ivs_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  IvsController? controller;

  initialize(IvsController controller) async {
    subscribe(controller.eventStream);
    setState(() {
      this.controller = controller;
    });
  }

  Future<void> subscribe(Stream stream) async {
    await for (final event in stream) {
      if (event is StateChanged) {
        setState(() {});
      }
    }
  }

  void togglePlay() {
    if (controller?.state == IvsState.playing) {
      controller?.pause();
    } else {
      controller?.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Stack(children: [
            Center(child: IvsPlayer(onControllerCreated: initialize)),
            Align(
              alignment: Alignment.topCenter,
              child: UrlBar(controller: controller),
            ),
            if (controller?.state == IvsState.buffering)
              Center(child: CircularProgressIndicator()),
          ]),
          floatingActionButton: FloatingActionButton(
            child: controller?.state == IvsState.playing
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
  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>? banner;

  @override
  void initState() {
    super.initState();
    loadUrl();

    SchedulerBinding.instance!.addPostFrameCallback((_) {
      toggle();
    });
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
            content: Container(
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
          ElevatedButton(
            onPressed: saveAndLoadUrl,
            child: Text("Open"),
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

  @override
  void didUpdateWidget(UrlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final controller = widget.controller;
      if (controller != null) {
        subscribeIvsEvent(controller.eventStream);
      }
    }
  }

  subscribeIvsEvent(Stream<dynamic> stream) async {
    await for (final event in stream) {
      print(event);
      if (event is DurationChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("duration: ${event.duration}")));
      } else if (event is Failed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed: ${event.error}")));
      }
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
