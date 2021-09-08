package com.example.ivs_player

import androidx.annotation.NonNull

import android.content.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.*
import io.flutter.plugin.platform.*

/** IvsPlayerPlugin */
class IvsPlayerPlugin : FlutterPlugin {
  private val managers = mutableListOf<IvsManager>()

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    binding
      .platformViewRegistry
      .registerViewFactory("ivs_player",
        object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
          override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            val manager = IvsManager(viewId, binding.binaryMessenger)
            manager.context = context
            managers.add(manager)

            return manager.platformView
          }
        })
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }
}
