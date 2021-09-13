package com.example.ivs_player

import android.content.*
import android.net.*
import android.view.*
import com.amazonaws.ivs.player.*
import io.flutter.plugin.common.*
import io.flutter.plugin.platform.*

internal class IvsManager(id: Int, messenger: BinaryMessenger, context: Context) {
  private val methodChannel = MethodChannel(messenger, "ivs_player:$id")
  private val eventChannel = EventChannel(messenger, "ivs_event:$id")
  private val surfaceView = SurfaceView(context)
  private val player = Player.Factory.create(context)

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

    surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
      override fun surfaceCreated(holder: SurfaceHolder) {
        player.setSurface(holder.surface)
      }

      override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
      }

      override fun surfaceDestroyed(holder: SurfaceHolder) {
        player.setSurface(null)
      }
    })
  }

  val platformView: PlatformView
    get() {
      return object : PlatformView {
        override fun getView() = surfaceView

        override fun dispose() {
          this@IvsManager.dispose()
        }
      }
    }

  fun dispose() {
    methodChannel.setMethodCallHandler(null)
    eventSink?.endOfStream()
    eventChannel.setStreamHandler(null)
  }

  private fun transferState() {
    val listener = this.listener ?: return
    listener.onStateChanged(player.state)
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
            player.load(uri)
            result.success(null)
          }
          else -> result.error("invalid_argument", "Provided url is not valid", null)
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
      else -> {
        result.notImplemented()
      }
    }
  }
}
