package com.my.reminders

import io.flutter.app.FlutterApplication

class FlutterApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        // Keep FlutterApplication context alive for notifications
    }
}
