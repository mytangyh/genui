package com.example.hexin_demo

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.os.Handler
import android.os.Looper
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlin.random.Random

/**
 * Native chart view that simulates real-time stock price updates.
 */
class NativeChartView(
    context: Context,
    private val viewId: Int,
    private val messenger: BinaryMessenger,
    creationParams: Map<String, Any>?
) : PlatformView {

    private val chartView: ChartCanvasView
    private val channel: MethodChannel
    private val handler = Handler(Looper.getMainLooper())
    private var refreshInterval: Long = 1000
    private var isRunning = false
    private val tag = "NativeChartView"

    init {
        val stockCode = creationParams?.get("stockCode") as? String ?: "000001"
        refreshInterval = (creationParams?.get("refreshInterval") as? Number)?.toLong() ?: 1000

        android.util.Log.d(tag, "[$viewId] Created with stockCode=$stockCode, interval=$refreshInterval")

        chartView = ChartCanvasView(context, stockCode)
        channel = MethodChannel(messenger, "native-chart-view-$viewId")

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    android.util.Log.d(tag, "[$viewId] Received START command, current isRunning=$isRunning")
                    startUpdates()
                    result.success(null)
                }
                "stop" -> {
                    android.util.Log.d(tag, "[$viewId] Received STOP command, current isRunning=$isRunning")
                    stopUpdates()
                    result.success(null)
                }
                "updateData" -> {
                    val prices = call.argument<List<Double>>("prices")
                    if (prices != null) {
                        chartView.updatePrices(prices)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Generate initial data immediately for first render
        chartView.generateMockData()
        android.util.Log.d(tag, "[$viewId] Init complete, waiting for START command from Flutter")
    }

    private val updateRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                chartView.generateMockData()
                android.util.Log.d(tag, "[$viewId] Data refreshed, count=${chartView.updateCount}")
                handler.postDelayed(this, refreshInterval)
            }
        }
    }

    private fun startUpdates() {
        if (!isRunning) {
            isRunning = true
            android.util.Log.d(tag, "[$viewId] START updates")
            handler.post(updateRunnable)
        }
    }

    private fun stopUpdates() {
        android.util.Log.d(tag, "[$viewId] STOP updates")
        isRunning = false
        handler.removeCallbacks(updateRunnable)
    }

    override fun getView(): View = chartView

    override fun dispose() {
        android.util.Log.d(tag, "[$viewId] Disposed")
        stopUpdates()
        channel.setMethodCallHandler(null)
    }
}

/**
 * Simple canvas-based chart view.
 */
class ChartCanvasView(context: Context, private val stockCode: String) : View(context) {

    private val linePaint = Paint().apply {
        color = Color.parseColor("#FF4D4F")
        strokeWidth = 4f
        style = Paint.Style.STROKE
        isAntiAlias = true
    }

    private val textPaint = Paint().apply {
        color = Color.WHITE
        textSize = 32f
        isAntiAlias = true
    }

    private val countPaint = Paint().apply {
        color = Color.parseColor("#2BCCFF")
        textSize = 48f
        isAntiAlias = true
        isFakeBoldText = true
    }

    private val bgPaint = Paint().apply {
        color = Color.parseColor("#1E1E1E")
    }

    private var prices: List<Double> = emptyList()
    private val path = Path()
    var updateCount = 0
        private set

    fun updatePrices(newPrices: List<Double>) {
        prices = newPrices
        invalidate()
    }

    fun generateMockData() {
        updateCount++
        val basePrice = 100.0
        val newPrices = (0 until 50).map { i ->
            basePrice + Random.nextDouble(-5.0, 5.0) + (i * 0.1) + (updateCount % 10)
        }
        updatePrices(newPrices)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        // Background
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)

        // Title
        canvas.drawText("Stock: $stockCode (Native)", 16f, 40f, textPaint)

        // Update counter - LARGE and visible
        canvas.drawText("刷新次数: $updateCount", 16f, height - 20f, countPaint)

        if (prices.isEmpty()) return

        // Draw price line
        val minPrice = prices.minOrNull() ?: 0.0
        val maxPrice = prices.maxOrNull() ?: 100.0
        val priceRange = (maxPrice - minPrice).coerceAtLeast(1.0)

        val chartTop = 60f
        val chartBottom = height - 60f
        val chartHeight = chartBottom - chartTop
        val stepX = width.toFloat() / (prices.size - 1).coerceAtLeast(1)

        path.reset()
        prices.forEachIndexed { index, price ->
            val x = index * stepX
            val y = chartTop + ((maxPrice - price) / priceRange * chartHeight).toFloat()
            if (index == 0) {
                path.moveTo(x, y)
            } else {
                path.lineTo(x, y)
            }
        }
        canvas.drawPath(path, linePaint)

        // Current price
        val currentPrice = prices.lastOrNull() ?: 0.0
        canvas.drawText(
            String.format("%.2f", currentPrice),
            width - 120f,
            40f,
            textPaint
        )
    }
}

/**
 * Factory to create NativeChartView instances.
 */
class NativeChartViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as? Map<String, Any>
        return NativeChartView(context, viewId, messenger, creationParams)
    }
}
