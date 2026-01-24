package com.secgo.kiosk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
  private var receiver: BroadcastReceiver? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS_CHANNEL).setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          eventSink = events
        }

        override fun onCancel(arguments: Any?) {
          eventSink = null
        }
      },
    )

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "isNotificationListenerEnabled" -> result.success(isNotificationListenerEnabled())
        "getAlipayNotificationState" -> result.success(getAlipayNotificationState())
        "getLatestAlipayNotification" -> result.success(getLatestAlipayNotification())
        "getLatestAlipayPaymentNotification" -> result.success(getLatestAlipayPaymentNotification())
        "getActiveAlipayNotificationsSnapshot" -> result.success(getActiveAlipayNotificationsSnapshot())
        "getWechatNotificationState" -> result.success(getWechatNotificationState())
        "getLatestWechatNotification" -> result.success(getLatestWechatNotification())
        "getLatestWechatPaymentNotification" -> result.success(getLatestWechatPaymentNotification())
        "getActiveWechatNotificationsSnapshot" -> result.success(getActiveWechatNotificationsSnapshot())
        "openLauncherHome" -> {
          val intent =
            Intent(Intent.ACTION_MAIN).apply {
              addCategory(Intent.CATEGORY_HOME)
              addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
          startActivity(intent)
          result.success(true)
        }
        "openApp" -> {
          val pkg = call.argument<String>("packageName")?.trim()
          if (pkg.isNullOrBlank()) {
            result.success(false)
            return@setMethodCallHandler
          }
          val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
          if (launchIntent == null) {
            result.success(false)
            return@setMethodCallHandler
          }
          launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          startActivity(launchIntent)
          result.success(true)
        }
        "listLaunchableApps" -> {
          val intent =
            Intent(Intent.ACTION_MAIN).apply {
              addCategory(Intent.CATEGORY_LAUNCHER)
            }

          val activities =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
              packageManager.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
            } else {
              @Suppress("DEPRECATION")
              packageManager.queryIntentActivities(intent, 0)
            }

          val resultList =
            activities.map { ri ->
              val label = ri.loadLabel(packageManager)?.toString() ?: ""
              val pkg = ri.activityInfo?.packageName ?: ""
              mapOf(
                "packageName" to pkg,
                "label" to label,
              )
            }.filter { it["packageName"]?.isNotBlank() == true }
          result.success(resultList)
        }
        "openNotificationListenerSettings" -> {
          startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
          result.success(true)
        }
        else -> result.notImplemented()
      }
    }
  }

  override fun onCreate(savedInstanceState: android.os.Bundle?) {
    super.onCreate(savedInstanceState)

    receiver =
      object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
          when (intent.action) {
            SecgoNotificationListenerService.ACTION_NOTIFICATION_STATE -> {
              val hasAlipay = intent.getBooleanExtra(SecgoNotificationListenerService.KEY_HAS_ALIPAY, false)
              val hasWechat = intent.getBooleanExtra(SecgoNotificationListenerService.KEY_HAS_WECHAT, false)
              val updatedAt = intent.getLongExtra(SecgoNotificationListenerService.KEY_UPDATED_AT_MS, 0L)
              val latestAlipayJson = intent.getStringExtra(SecgoNotificationListenerService.KEY_LAST_ALIPAY_JSON)
              val latestAlipayPaymentJson =
                intent.getStringExtra(SecgoNotificationListenerService.KEY_LAST_ALIPAY_PAYMENT_JSON)
              val latestWechatJson = intent.getStringExtra(SecgoNotificationListenerService.KEY_LAST_WECHAT_JSON)
              val latestWechatPaymentJson =
                intent.getStringExtra(SecgoNotificationListenerService.KEY_LAST_WECHAT_PAYMENT_JSON)
              eventSink?.success(
                mapOf(
                  "type" to "state",
                  "hasAlipay" to hasAlipay,
                  "hasWechat" to hasWechat,
                  "updatedAtMs" to updatedAt,
                  "alipay" to (parseJsonToMap(latestAlipayJson) ?: emptyMap<String, Any>()),
                  "alipayPayment" to (parseJsonToMap(latestAlipayPaymentJson) ?: emptyMap<String, Any>()),
                  "wechat" to (parseJsonToMap(latestWechatJson) ?: emptyMap<String, Any>()),
                  "wechatPayment" to (parseJsonToMap(latestWechatPaymentJson) ?: emptyMap<String, Any>()),
                ),
              )
            }
            SecgoNotificationListenerService.ACTION_NOTIFICATION_POSTED -> {
              val postedJson = intent.getStringExtra(SecgoNotificationListenerService.KEY_POSTED_JSON)
              Log.i("SecgoNotif", "ACTION_NOTIFICATION_POSTED eventSink=${eventSink != null} postedJson=${postedJson != null}")
              eventSink?.success(
                mapOf(
                  "type" to "posted",
                  "notification" to (parseJsonToMap(postedJson) ?: emptyMap<String, Any>()),
                ),
              )
            }
            else -> {
            }
          }
        }
      }

    val filter =
      IntentFilter().apply {
        addAction(SecgoNotificationListenerService.ACTION_NOTIFICATION_STATE)
        addAction(SecgoNotificationListenerService.ACTION_NOTIFICATION_POSTED)
      }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
    } else {
      @Suppress("DEPRECATION")
      registerReceiver(receiver, filter)
    }
  }

  override fun onDestroy() {
    receiver?.let {
      try {
        unregisterReceiver(it)
      } catch (_: Exception) {
      }
    }
    receiver = null
    super.onDestroy()
  }

  private fun isNotificationListenerEnabled(): Boolean {
    val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
    return enabled.contains(packageName)
  }

  private fun getAlipayNotificationState(): Map<String, Any> {
    val prefs = getSharedPreferences(SecgoNotificationListenerService.PREFS_NAME, Context.MODE_PRIVATE)
    val hasAlipay = prefs.getBoolean(SecgoNotificationListenerService.KEY_HAS_ALIPAY, false)
    val updatedAt = prefs.getLong(SecgoNotificationListenerService.KEY_UPDATED_AT_MS, 0L)
    return mapOf(
      "enabled" to isNotificationListenerEnabled(),
      "hasAlipay" to hasAlipay,
      "updatedAtMs" to updatedAt,
    )
  }

  private fun getLatestAlipayNotification(): Map<String, Any>? {
    val prefs = getSharedPreferences(SecgoNotificationListenerService.PREFS_NAME, Context.MODE_PRIVATE)
    val json = prefs.getString(SecgoNotificationListenerService.KEY_LAST_ALIPAY_JSON, null) ?: return null
    return parseJsonToMap(json)
  }

  private fun getLatestAlipayPaymentNotification(): Map<String, Any>? {
    val prefs = getSharedPreferences(SecgoNotificationListenerService.PREFS_NAME, Context.MODE_PRIVATE)
    val json = prefs.getString(SecgoNotificationListenerService.KEY_LAST_ALIPAY_PAYMENT_JSON, null) ?: return null
    return parseJsonToMap(json)
  }

  private fun getActiveAlipayNotificationsSnapshot(): List<Map<String, Any>> {
    val prefs = getSharedPreferences(SecgoNotificationListenerService.PREFS_NAME, Context.MODE_PRIVATE)
    val json = prefs.getString(SecgoNotificationListenerService.KEY_ACTIVE_ALIPAY_SNAPSHOT_JSON, null) ?: return emptyList()
    return parseJsonToListOfMaps(json)
  }

  private fun getWechatNotificationState(): Map<String, Any> {
    val prefs = getSharedPreferences(SecgoNotificationListenerService.PREFS_NAME, Context.MODE_PRIVATE)
    val hasWechat = prefs.getBoolean(SecgoNotificationListenerService.KEY_HAS_WECHAT, false)
    val updatedAt = prefs.getLong(SecgoNotificationListenerService.KEY_UPDATED_AT_MS, 0L)
    return mapOf(
      "enabled" to isNotificationListenerEnabled(),
      "hasWechat" to hasWechat,
      "updatedAtMs" to updatedAt,
    )
  }

  private fun getLatestWechatNotification(): Map<String, Any>? {
    val prefs = getSharedPreferences(SecgoNotificationListenerService.PREFS_NAME, Context.MODE_PRIVATE)
    val json = prefs.getString(SecgoNotificationListenerService.KEY_LAST_WECHAT_JSON, null) ?: return null
    return parseJsonToMap(json)
  }

  private fun getLatestWechatPaymentNotification(): Map<String, Any>? {
    val prefs = getSharedPreferences(SecgoNotificationListenerService.PREFS_NAME, Context.MODE_PRIVATE)
    val json = prefs.getString(SecgoNotificationListenerService.KEY_LAST_WECHAT_PAYMENT_JSON, null) ?: return null
    return parseJsonToMap(json)
  }

  private fun getActiveWechatNotificationsSnapshot(): List<Map<String, Any>> {
    val prefs = getSharedPreferences(SecgoNotificationListenerService.PREFS_NAME, Context.MODE_PRIVATE)
    val json = prefs.getString(SecgoNotificationListenerService.KEY_ACTIVE_WECHAT_SNAPSHOT_JSON, null) ?: return emptyList()
    return parseJsonToListOfMaps(json)
  }

  private fun parseJsonToMap(json: String?): Map<String, Any>? {
    if (json == null || json.isBlank()) return null
    return try {
      val obj = JSONObject(json)
      val map = mutableMapOf<String, Any>()
      val it = obj.keys()
      while (it.hasNext()) {
        val k = it.next()
        val v = obj.opt(k)
        if (v == null || v == JSONObject.NULL) continue
        map[k] = v
      }
      map
    } catch (_: Exception) {
      null
    }
  }

  private fun parseJsonToListOfMaps(json: String?): List<Map<String, Any>> {
    if (json == null || json.isBlank()) return emptyList()
    return try {
      val arr = JSONArray(json)
      val result = mutableListOf<Map<String, Any>>()
      for (i in 0 until arr.length()) {
        val obj = arr.optJSONObject(i) ?: continue
        result.add(parseJsonToMap(obj.toString()) ?: continue)
      }
      result
    } catch (_: Exception) {
      emptyList()
    }
  }

  companion object {
    private const val METHOD_CHANNEL = "com.secgo.kiosk/notification_listener"
    private const val EVENTS_CHANNEL = "com.secgo.kiosk/notifications"

    @Volatile
    private var eventSink: EventChannel.EventSink? = null
  }
}
