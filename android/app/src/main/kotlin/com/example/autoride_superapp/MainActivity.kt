package com.example.autoride_superapp

import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import java.util.Locale

class MainActivity : FlutterActivity() {
    override fun attachBaseContext(newBase: Context) {
        val locale = Locale("km")
        Locale.setDefault(locale)
        val config = Configuration(newBase.resources.configuration)
        config.setLocale(locale)
        super.attachBaseContext(newBase.createConfigurationContext(config))
    }
}
