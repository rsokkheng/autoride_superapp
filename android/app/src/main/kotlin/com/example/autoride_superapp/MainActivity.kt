package com.example.autoride_superapp

import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private const val LOCALE_CHANNEL = "app/locale"
        private const val PREFS_NAME     = "app_prefs"
        private const val KEY_LOCALE     = "locale"
    }

    // Called once at Activity creation — apply the saved locale so Google Maps
    // SDK (which reads the base context locale) uses the correct language.
    override fun attachBaseContext(newBase: Context) {
        val saved = newBase
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_LOCALE, null)
        val langCode = saved ?: Locale.getDefault().language
        val locale   = Locale(langCode)
        Locale.setDefault(locale)
        val config = Configuration(newBase.resources.configuration)
        config.setLocale(locale)
        super.attachBaseContext(newBase.createConfigurationContext(config))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCALE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setLocale" -> {
                        val langCode  = call.arguments as? String ?: "en"
                        val newLocale = Locale(langCode)

                        // 1. Java default locale (affects many SDK internals)
                        Locale.setDefault(newLocale)

                        // 2. Activity resources
                        val actConfig = Configuration(resources.configuration)
                        actConfig.setLocale(newLocale)
                        @Suppress("DEPRECATION")
                        resources.updateConfiguration(actConfig, resources.displayMetrics)

                        // 3. Application context resources — this is what
                        //    google_maps_flutter_android uses for new MapViews
                        val appRes = applicationContext.resources
                        val appConfig = Configuration(appRes.configuration)
                        appConfig.setLocale(newLocale)
                        @Suppress("DEPRECATION")
                        appRes.updateConfiguration(appConfig, appRes.displayMetrics)

                        // 4. Persist so attachBaseContext picks it up next time
                        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            .edit()
                            .putString(KEY_LOCALE, langCode)
                            .apply()

                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
