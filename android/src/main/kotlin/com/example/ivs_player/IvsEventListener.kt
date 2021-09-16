package com.example.ivs_player

import com.amazonaws.ivs.player.*
import io.flutter.plugin.common.*

internal class IvsEventListener(private val sink: EventChannel.EventSink) : Player.Listener() {
  override fun onCue(cue: Cue) {
    sink.success(mapOf("type" to "cue", "startTime" to cue.startTime, "endTime" to cue.endTime))
  }

  override fun onDurationChanged(newDuration: Long) {
    sink.success(mapOf(
      "type" to "duration_changed",
      "duration" to newDuration,
    ))
  }

  override fun onStateChanged(newState: Player.State) {
    val state = newState.name.lowercase()
    sink.success(mapOf(
      "type" to "state_changed",
      "state" to state,
    ))
  }

  override fun onError(exception: PlayerException) {
    exception.apply {
      sink.error("$code", errorMessage, mapOf(
        "type" to "$errorType",
        "code" to code,
        "message" to message,
        "source" to source,
        "stack" to stackTraceToString(),
      ))
    }
  }

  override fun onRebuffering() {
    sink.success(mapOf("type" to "rebuffer"))
  }

  override fun onSeekCompleted(position: Long) {
    sink.success(mapOf("type" to "seek_completed", "position" to position))
  }

  override fun onVideoSizeChanged(p0: Int, p1: Int) {
    // use onQualityChanged instead
  }

  override fun onQualityChanged(quality: Quality) {
    sink.success(mapOf("type" to "quality_changed", "quality" to quality.run {
      mapOf(
        "bitrate" to bitrate,
        "codecs" to codecs,
        "frame_rate" to framerate,
        "height" to height,
        "name" to name,
        "width" to width,
      )
    }))
  }
}