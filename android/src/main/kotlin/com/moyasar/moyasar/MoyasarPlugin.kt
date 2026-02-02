package com.moyasar.moyasar

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import org.json.JSONObject

class MoyasarPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    companion object {
        private const val CHANNEL_NAME = "flutter.moyasar.com/samsung_pay"
        private const val SAMSUNG_PAY_REQUEST_CODE = 1001
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSamsungPayAvailable" -> {
                result.success(isSamsungPayAvailable())
            }
            "presentSamsungPay" -> {
                val args = call.arguments as? Map<*, *>
                if (args != null) {
                    presentSamsungPay(args, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isSamsungPayAvailable(): Boolean {
        return try {
            // Check if Samsung Pay SDK is available
            // Note: This requires Samsung Pay SDK to be added as a dependency
            // For now, we'll check if Samsung Pay app is installed
            val context = activity?.applicationContext
            if (context != null) {
                val intent = context.packageManager.getLaunchIntentForPackage("com.samsung.android.spay")
                intent != null
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun presentSamsungPay(args: Map<*, *>, result: MethodChannel.Result) {
        val activity = this.activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        try {
            val merchantId = args["merchantId"] as? String
            val label = args["label"] as? String
            val amount = args["amount"] as? String
            val currencyCode = args["currencyCode"] as? String ?: "SAR"
            val countryCode = args["countryCode"] as? String ?: "SA"

            if (merchantId == null || label == null || amount == null) {
                result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                return
            }

            // Create Samsung Pay payment intent
            // Note: This is a placeholder implementation
            // Actual implementation requires Samsung Pay SDK integration
            val paymentData = JSONObject().apply {
                put("merchantId", merchantId)
                put("label", label)
                put("amount", amount)
                put("currencyCode", currencyCode)
                put("countryCode", countryCode)
            }

            // For now, we'll simulate a payment token
            // In production, this should integrate with Samsung Pay SDK
            // Example: SamsungPay.getInstance().startPay(activity, paymentRequest)
            
            // Simulated token response (replace with actual Samsung Pay SDK call)
            val token = "samsung_pay_token_${System.currentTimeMillis()}"
            
            val resultMap = mapOf("token" to token)
            channel.invokeMethod("onSamsungPayResult", resultMap)
            result.success(true)

        } catch (e: Exception) {
            result.error("SAMSUNG_PAY_ERROR", e.message, null)
            channel.invokeMethod("onSamsungPayError", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            if (requestCode == SAMSUNG_PAY_REQUEST_CODE) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    // Handle Samsung Pay result
                    // Extract token from Samsung Pay SDK response
                    val token = data.getStringExtra("token") ?: ""
                    val resultMap = mapOf("token" to token)
                    channel.invokeMethod("onSamsungPayResult", resultMap)
                } else {
                    channel.invokeMethod("onSamsungPayError", null)
                }
                true
            } else {
                false
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
