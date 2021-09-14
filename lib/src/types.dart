enum PlayerState {
  idle,
  ready,
  buffering,
  playing,
  ended,
}

class PlayerEvent {}

class Failed extends PlayerEvent {
  final String error;

  Failed(this.error);
}

class Rebuffer extends PlayerEvent {}

class NetworkBecameUnavailable extends PlayerEvent {}

class Quality {
  int bitrate;
  int width;
  int height;
  double frameRate;
  String name;
  String codecs;

  Quality({
    this.bitrate = 0,
    this.width = 0,
    this.height = 0,
    this.frameRate = 0,
    this.name = "",
    this.codecs = "",
  });
}
