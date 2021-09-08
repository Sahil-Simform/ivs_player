import 'package:flutter/material.dart';
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
  bool isPlaying = false;
  bool isAddressVisible = true;
  IvsController? controller;
  String url = '';
  TextEditingController urlController = TextEditingController();

  initialize(IvsController controller) async {
    setState(() {
      this.controller = controller;
    });

    final preferences = await SharedPreferences.getInstance();
    final url = await preferences.getString('url');
    if (url != null) {
      urlController.text = url;
      controller.load(url);
    }
  }

  saveAndLoadUrl() async {
    final uri = Uri.parse(urlController.text);
    await controller?.load('$uri');
    setState(() {
      isAddressVisible = false;
    });

    final preferences = await SharedPreferences.getInstance();
    preferences.setString('url', '$uri');
  }

  void togglePlay() {
    if (isPlaying) {
      controller?.pause();
    } else {
      controller?.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Stack(children: [
            Center(
                child: IvsPlayer(
              onControllerCreated: initialize,
            )),
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: isAddressVisible
                      ? Container(
                          color: Colors.white,
                          height: 60,
                          child: Row(children: [
                            Expanded(
                                child: TextField(
                              style: TextStyle(fontSize: 20),
                              controller: urlController,
                            )),
                            ElevatedButton(
                              onPressed: saveAndLoadUrl,
                              child: Text("OK"),
                            )
                          ]),
                        )
                      : GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              isAddressVisible = !isAddressVisible;
                            });
                          },
                          child: SizedBox(height: 60),
                        ),
                ))
          ]),
          floatingActionButton: FloatingActionButton(
            child: isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            onPressed: togglePlay,
          )),
    );
  }
}
