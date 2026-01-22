package com.example.hexin_demo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register native chart view factory
        flutterEngine.platformViewsController.registry
            .registerViewFactory(
                "native-chart-view",
                NativeChartViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
    }
}
