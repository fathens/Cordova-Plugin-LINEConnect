package org.fathens.cordova.plugin.lineconnect

import org.apache.cordova.*
import org.json.*
import jp.line.android.sdk.LineSdkContextManager
import jp.line.android.sdk.api.FutureStatus
import jp.line.android.sdk.login.LineLoginFuture
import jp.line.android.sdk.model.Profile

public class LINEConnect : CordovaPlugin() {

    private class PluginContext(val holder: LINEConnect, val action: String, val callback: CallbackContext) {
        fun error(msg: String?) = callback.error(msg)
        fun success() = callback.success(null as? String)
        fun success(msg: String?) = callback.success(msg)
        fun success(obj: JSONObject?) {
            if (obj != null) {
                callback.success(obj)
            } else {
                success()
            }
        }
    }

    private var context: PluginContext? = null

    override fun pluginInitialize() {
        LineSdkContextManager.initialize(cordova.activity.applicationContext)
    }

    override fun execute(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {
        try {
            val method = javaClass.getMethod(action, args.javaClass)
            if (method != null) {
                cordova.threadPool.execute {
                    context = PluginContext(this, action, callbackContext)
                    method.invoke(this, args)
                }
                return true
            } else {
                return false
            }
        } catch (e: NoSuchMethodException) {
            return false
        }
    }

    public fun login(args: JSONArray) {
        LineSdkContextManager.getSdkContext().authManager.login(cordova.activity).addFutureListener { future ->
            when (future.progress) {
                LineLoginFuture.ProgressOfLogin.SUCCESS -> context?.success()
                LineLoginFuture.ProgressOfLogin.CANCELED -> context?.error("Login canceled.")
                else -> context?.error("Error: ${future.cause}")
            }
        }
    }

    public fun logout(args: JSONArray) {
        val future = LineSdkContextManager.getSdkContext().authManager.logout()
        future.get()
        context?.success()
    }

    public fun getName(args: JSONArray) {
        getProfile { profile, error ->
            if (profile != null) {
                context?.success(profile.displayName)
            } else {
                context?.error("Error: ${error}")
            }
        }
    }

    public fun getId(args: JSONArray) {
        getProfile { profile, error ->
            if (profile != null) {
                context?.success(profile.mid)
            } else {
                context?.error("Error: ${error}")
            }
        }
    }

    fun getProfile(callback: (Profile?, Throwable?) -> Unit) {
        LineSdkContextManager.getSdkContext().apiClient.getMyProfile { future ->
            when (future.status) {
                FutureStatus.SUCCESS -> {
                    callback(future.responseObject, null)
                }
                else -> callback(null, future.cause)
            }
        }
    }
}
