package com.example.ivs_player

// I don't know why flutter can't detect this plugin as embedding V2 with wildcard.
import androidx.annotation.NonNull

import android.content.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.*
import io.flutter.plugin.platform.*

/** IvsPlayerPlugin */
class IvsPlayerPlugin : FlutterPlugin {
  private val managers = mutableListOf<FlutterIvsPlayer>()

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    binding
      .platformViewRegistry
      .registerViewFactory("ivs_player",
        object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
          override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            val manager = FlutterIvsPlayer(viewId, binding.binaryMessenger, context)
            managers.add(manager)

            return manager.platformView
          }
        })
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }
}
