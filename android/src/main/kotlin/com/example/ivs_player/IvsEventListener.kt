package com.example.ivs_player

import com.amazonaws.ivs.player.*
import io.flutter.plugin.common.*

internal class IvsEventListener(private val sink: EventChannel.EventSink) : Player.Listener() {
  override fun onCue(p0: Cue) {
    sink.success(mapOf("type" to "cue"))
  }

  override fun onDurationChanged(newDuration: Long) {
    sink.success(mapOf(
      "type" to "duration_changed",
      "new_duration" to newDuration,
    ))
  }

  override fun onStateChanged(newState: Player.State) {
    sink.success(mapOf(
      "type" to "state_changed",
      "state" to newState.name.lowercase(),
    ))
  }

  override fun onError(exception: PlayerException) {
    exception.apply {
      sink.error("$code", errorMessage, mapOf(
        "code" to code,
        "type" to errorType,
        "message" to message,
        "source" to source,
        "stack" to stackTraceToString()
      ))
    }
  }

  override fun onRebuffering() {
    sink.success(mapOf("type" to "rebuffering"))
  }

  override fun onSeekCompleted(p0: Long) {
    sink.success(mapOf("type" to "seek_completed"))
  }

  override fun onVideoSizeChanged(p0: Int, p1: Int) {
    sink.success(mapOf("type" to "video_size_changed"))
  }

  override fun onQualityChanged(p0: Quality) {
    sink.success(mapOf("type" to "quality_changed"))
  }
}