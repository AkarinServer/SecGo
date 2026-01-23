package com.secgo.kiosk

import android.app.Notification
import android.content.Context
import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

class SecgoNotificationListenerService : NotificationListenerService() {
  override fun onListenerConnected() {
    super.onListenerConnected()
    updateState()
  }

  override fun onNotificationPosted(sbn: StatusBarNotification) {
    if (sbn.packageName == ALIPAY_PACKAGE) {
      sendBroadcast(
        Intent(ACTION_NOTIFICATION_POSTED).apply {
          putExtra(KEY_POSTED_JSON, buildNotificationJson(sbn).toString())
        },
      )
    }
    updateState()
  }

  override fun onNotificationRemoved(sbn: StatusBarNotification) {
    updateState()
  }

  private fun updateState() {
    val hasAlipay = activeNotifications?.any { it.packageName == ALIPAY_PACKAGE } ?: false
    val latestAlipay = getLatestAlipay(activeNotifications)
    val latestAlipayPayment = getLatestAlipayPayment(activeNotifications)
    val activeSnapshot = buildActiveAlipaySnapshot(activeNotifications)
    val latestAlipayJson = latestAlipay?.let { buildNotificationJson(it).toString() }
    val latestAlipayPaymentJson = latestAlipayPayment?.let { buildNotificationJson(it).toString() }
    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    prefs.edit()
      .putBoolean(KEY_HAS_ALIPAY, hasAlipay)
      .putString(KEY_LAST_ALIPAY_JSON, latestAlipayJson)
      .putString(KEY_LAST_ALIPAY_PAYMENT_JSON, latestAlipayPaymentJson)
      .putString(KEY_ACTIVE_ALIPAY_SNAPSHOT_JSON, activeSnapshot)
      .putLong(KEY_UPDATED_AT_MS, System.currentTimeMillis())
      .apply()

    sendBroadcast(
      Intent(ACTION_NOTIFICATION_STATE).apply {
        putExtra(KEY_HAS_ALIPAY, hasAlipay)
        putExtra(KEY_LAST_ALIPAY_JSON, latestAlipayJson)
        putExtra(KEY_LAST_ALIPAY_PAYMENT_JSON, latestAlipayPaymentJson)
        putExtra(KEY_ACTIVE_ALIPAY_SNAPSHOT_JSON, activeSnapshot)
        putExtra(KEY_UPDATED_AT_MS, System.currentTimeMillis())
      },
    )
  }

  private fun getLatestAlipay(notifications: Array<StatusBarNotification>?): StatusBarNotification? {
    if (notifications == null || notifications.isEmpty()) return null
    return notifications
      .filter { it.packageName == ALIPAY_PACKAGE }
      .maxByOrNull { it.postTime }
  }

  private fun getLatestAlipayPayment(notifications: Array<StatusBarNotification>?): StatusBarNotification? {
    if (notifications == null || notifications.isEmpty()) return null
    return notifications
      .filter { it.packageName == ALIPAY_PACKAGE }
      .filter { isPaymentLike(it) }
      .maxByOrNull { it.postTime }
  }

  private fun isPaymentLike(sbn: StatusBarNotification): Boolean {
    val extras = sbn.notification.extras
    val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
    val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
    val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
    val combined = "$title $text $bigText"
    if (combined.contains("成功收款")) return true
    if (combined.contains("收款") && combined.contains("元")) return true
    return false
  }

  private fun buildNotificationJson(sbn: StatusBarNotification): JSONObject {
    val n = sbn.notification
    val extras = n.extras
    val json =
      JSONObject()
        .put("package", sbn.packageName)
        .put("key", sbn.key)
        .put("id", sbn.id)
        .put("channelId", n.channelId ?: JSONObject.NULL)
        .put("postTime", sbn.postTime)
        .put("when", n.`when`)
        .put("category", n.category ?: JSONObject.NULL)
        .put("title", extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: JSONObject.NULL)
        .put("text", extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: JSONObject.NULL)
        .put("subText", extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: JSONObject.NULL)
        .put("bigText", extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: JSONObject.NULL)
        .put("infoText", extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString() ?: JSONObject.NULL)
    return json
  }

  private fun buildActiveAlipaySnapshot(notifications: Array<StatusBarNotification>?): String {
    val list = JSONArray()
    if (notifications == null || notifications.isEmpty()) return list.toString()
    notifications
      .filter { it.packageName == ALIPAY_PACKAGE }
      .sortedByDescending { it.postTime }
      .forEach { list.put(buildNotificationJson(it)) }
    return list.toString()
  }

  companion object {
    const val ACTION_NOTIFICATION_STATE = "com.secgo.kiosk.NOTIFICATION_STATE"
    const val ACTION_NOTIFICATION_POSTED = "com.secgo.kiosk.NOTIFICATION_POSTED"
    const val PREFS_NAME = "secgo_notification_listener"
    const val KEY_HAS_ALIPAY = "has_alipay"
    const val KEY_LAST_ALIPAY_JSON = "last_alipay_json"
    const val KEY_LAST_ALIPAY_PAYMENT_JSON = "last_alipay_payment_json"
    const val KEY_ACTIVE_ALIPAY_SNAPSHOT_JSON = "active_alipay_snapshot_json"
    const val KEY_POSTED_JSON = "posted_json"
    const val KEY_UPDATED_AT_MS = "updated_at_ms"
    const val ALIPAY_PACKAGE = "com.eg.android.AlipayGphone"
  }
}
