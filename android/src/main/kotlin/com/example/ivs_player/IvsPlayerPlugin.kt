package com.example.ivs_player

// I don't know why flutter can't detect this plugin as embedding V2 with wildcard.
import androidx.annotation.NonNull

import android.content.*
import android.view.*
import com.amazonaws.ivs.player.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.*
import io.flutter.plugin.common.*
import io.flutter.plugin.platform.*

class IvsPlayerPlugin : FlutterPlugin, ActivityAware {
  private val players = mutableMapOf<Long, FlutterIvsPlayer>()
  private var methodChannel: MethodChannel? = null
  private var flutter: FlutterPlugin.FlutterPluginBinding? = null
  private var context: Context? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    flutter = binding

    this.methodChannel = MethodChannel(binding.binaryMessenger, "ivs_player").apply {
      setMethodCallHandler(this@IvsPlayerPlugin::handleMethodCall)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    players.values.forEach { it.dispose() }
    players.clear()
  }

  private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "create" -> {
        val player = flutter!!.run {
          FlutterIvsPlayer(
            binaryMessenger,
            textureRegistry.createSurfaceTexture(),
            context!!,
          )
        }
        players[player.id] = player
        result.success(player.id)
      }
      "delete" -> {
        val id = call.argument<Long>("id")?.toLong()
        if (players[id]?.dispose() == null) {
          result.error("no_player_found", "no player is assigned on id: $id", null)
        } else {
          result.success(null)
        }
      }
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    context = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    context = null

    players.values.forEach {
      if (it.player.state == Player.State.PLAYING) {
        it.isPaused = true
        it.player.setSurface(null)
        it.player.pause()
      }
    }
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    context = binding.activity
    players.values.forEach {
      if (it.isPaused) {
        it.player.play()
        it.player.setSurface(it.surface)
        it.isPaused = false
      }
    }
  }

  override fun onDetachedFromActivity() {
    context = null
  }
}
