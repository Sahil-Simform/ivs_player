package com.example.ivs_player

import android.content.*
import android.net.*
import com.amazonaws.ivs.player.*
import io.flutter.plugin.common.*
import io.flutter.plugin.platform.*

internal class IvsManager(id: Int, messenger: BinaryMessenger) {
  private val methodChannel = MethodChannel(messenger, "ivs_player:$id")
  private val eventChannel = EventChannel(messenger, "ivs_event:$id")

  init {
    methodChannel.setMethodCallHandler(this::onMethodCall)
    eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
      }

      override fun onCancel(arguments: Any?) {
        eventSink = null
      }
    })
  }

  var context: Context? = null
    set(value) {
      playerView = value?.let { PlayerView(it) }
      field = value
    }

  var eventSink: EventChannel.EventSink? = null
    set(value) {
      listener = value?.let { IvsEventListener(it) }
      field = value
    }

  val platformView: PlatformView
    get() {
      val view = playerView!!
      return object : PlatformView {
        override fun getView() = view

        override fun dispose() {
          this@IvsManager.dispose()
          playerView = null
        }
      }
    }

  var playerView: PlayerView? = null
    set(value) {
      listener?.let { listener ->
        field?.player?.removeListener(listener)
        value?.player?.addListener(listener)
      }
      field = value
    }

  private val player
    get() = playerView?.player

  private var listener: IvsEventListener? = null
    set(value) {
      playerView?.player?.let { player ->
        field?.let { player.removeListener(it) }
        value?.let { player.addListener(it) }
      }
      field = value
    }

  fun dispose() {
    methodChannel.setMethodCallHandler(null)
    eventSink?.endOfStream()
    eventChannel.setStreamHandler(null)
  }

  private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    try {
      handleCall(call, result)
    } catch (exception: Exception) {
      result.error("unknown_exception", "Native code threw", exception)
    }
  }

  private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "load" -> {
        val url = call.argument("src") as? String
        when (val uri = url?.let { Uri.parse(it) }) {
          is Uri -> {
            player!!.load(uri)
            result.success(null)
          }
          else -> result.error("invalid_argument", "Provided url is not valid", null)
        }
      }
      "play" -> {
        player!!.play()
        result.success(null)
      }
      "pause" -> {
        player!!.pause()
        result.success(null)
      }
      "seek_to" -> {
        when (val position = call.argument("position") as? Long) {
          is Long -> {
            player!!.seekTo(position)
            result.success(null)
          }
          else -> result.error("invalid_argument", "Provided url is not valid", null)
        }
      }
      "get_duration" -> {
        result.success(player!!.duration)
      }
      else -> {
        result.notImplemented()
      }
    }
  }
}
