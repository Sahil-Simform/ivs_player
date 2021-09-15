package com.example.ivs_player

import android.content.*
import android.net.*
import android.view.*
import com.amazonaws.ivs.player.*
import io.flutter.plugin.common.*
import io.flutter.view.*

internal class FlutterIvsPlayer(
  messenger: BinaryMessenger,
  texture: TextureRegistry.SurfaceTextureEntry,
  context: Context,
) {
  val id = texture.id()
  var isPaused = false

  private val methodChannel = MethodChannel(messenger, "ivs_player:$id")
  private val eventChannel = EventChannel(messenger, "ivs_event:$id")
  val surface = Surface(texture.surfaceTexture())
  val player = Player.Factory.create(context).apply { setSurface(surface) }

  init {
    methodChannel.setMethodCallHandler(this::onMethodCall)
    eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
        transferState()
      }

      override fun onCancel(arguments: Any?) {
        eventSink = null
      }
    })
  }

  fun dispose() {
    methodChannel.setMethodCallHandler(null)
    eventSink?.endOfStream()
    eventChannel.setStreamHandler(null)
    player.release()
    surface.release()
  }

  private fun transferState() {
    val listener = this.listener ?: return
    listener.onStateChanged(player.state)
    if (player.duration != 0L) {
      listener.onDurationChanged(player.duration)
      listener.onSeekCompleted(player.position)
    }
    if (player.quality.bitrate != 0) {
      listener.onQualityChanged(player.quality)
    }
  }

  private var eventSink: EventChannel.EventSink? = null
    set(value) {
      listener = value?.let { IvsEventListener(it) }
      field = value
    }

  private var listener: IvsEventListener? = null
    set(value) {
      field?.let { player.removeListener(it) }
      value?.let { player.addListener(it) }
      field = value
    }

  private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "load" -> {
        val url = call.argument("src") as? String
        when (val uri = url?.let { Uri.parse(it) }) {
          is Uri -> {
            player.load(uri)
            result.success(null)
          }
          else -> result.error("invalid_argument", "Provided url is not valid: $url", null)
        }
      }
      "play" -> {
        player.play()
        result.success(null)
      }
      "pause" -> {
        player.pause()
        result.success(null)
      }
      "seek_to" -> {
        when (val position = call.argument("position") as? Long) {
          is Long -> {
            player.seekTo(position)
            result.success(null)
          }
          else -> result.error("invalid_argument", "Provided url is not valid", null)
        }
      }
      "get_duration" -> {
        result.success(player.duration)
      }
      "dispose" -> {
        dispose()
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }
}
