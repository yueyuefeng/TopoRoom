package com.toporoom.app

import android.content.Context
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/**
 * Simple 户型图 canvas: walls as strokes, 门窗洞/垭口 marked on the host wall.
 */
class PlanCanvasView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : View(context, attrs) {
    var snapshot: PlanSnapshot = PlanSnapshot()
        set(value) {
            field = value
            invalidate()
        }

    private val wallPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF212121.toInt()
        strokeWidth = 8f
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.SQUARE
    }
    private val doorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF2E7D32.toInt()
        strokeWidth = 10f
        style = Paint.Style.STROKE
    }
    private val windowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF1565C0.toInt()
        strokeWidth = 10f
        style = Paint.Style.STROKE
    }
    private val archPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF6A1B9A.toInt()
        strokeWidth = 10f
        style = Paint.Style.STROKE
        pathEffect = DashPathEffect(floatArrayOf(16f, 10f), 0f)
    }
    private val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF424242.toInt()
        textSize = 28f
    }
    private val emptyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF757575.toInt()
        textSize = 32f
    }
    private val bgPaint = Paint().apply { color = 0xFFF7F3EA.toInt() }
    private val gridPaint = Paint().apply {
        color = 0x14212121
        strokeWidth = 1f
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)
        if (snapshot.walls.isEmpty()) {
            canvas.drawText("户型图（尚无墙）", 24f, height / 2f, emptyPaint)
            return
        }
        var minX = Double.POSITIVE_INFINITY
        var minY = Double.POSITIVE_INFINITY
        var maxX = Double.NEGATIVE_INFINITY
        var maxY = Double.NEGATIVE_INFINITY
        for (w in snapshot.walls) {
            minX = min(minX, min(w.x0, w.x1))
            minY = min(minY, min(w.y0, w.y1))
            maxX = max(maxX, max(w.x0, w.x1))
            maxY = max(maxY, max(w.y0, w.y1))
        }
        val pad = 48f
        val dx = (maxX - minX).coerceAtLeast(1.0)
        val dy = (maxY - minY).coerceAtLeast(1.0)
        val sx = (width - 2 * pad) / dx
        val sy = (height - 2 * pad) / dy
        val scale = min(sx, sy).toFloat()
        val ox = pad + ((width - 2 * pad) - dx * scale).toFloat() / 2f
        val oy = pad + ((height - 2 * pad) - dy * scale).toFloat() / 2f
        fun tx(x: Double) = ox + ((x - minX) * scale).toFloat()
        fun ty(y: Double) = height - (oy + ((y - minY) * scale).toFloat())

        var g = 0f
        while (g < width) {
            canvas.drawLine(g, 0f, g, height.toFloat(), gridPaint)
            g += 48f
        }
        g = 0f
        while (g < height) {
            canvas.drawLine(0f, g, width.toFloat(), g, gridPaint)
            g += 48f
        }

        for (wall in snapshot.walls) {
            val x0 = tx(wall.x0)
            val y0 = ty(wall.y0)
            val x1 = tx(wall.x1)
            val y1 = ty(wall.y1)
            canvas.drawLine(x0, y0, x1, y1, wallPaint)
            val len = hypot(wall.x1 - wall.x0, wall.y1 - wall.y0).coerceAtLeast(1.0)
            val ux = (wall.x1 - wall.x0) / len
            val uy = (wall.y1 - wall.y0) / len
            for (op in wall.openings) {
                val paint = when (op.kind) {
                    "window" -> windowPaint
                    "archway" -> archPaint
                    else -> doorPaint
                }
                val ax = wall.x0 + ux * op.offsetMm
                val ay = wall.y0 + uy * op.offsetMm
                val bx = ax + ux * op.widthMm
                val by = ay + uy * op.widthMm
                canvas.drawLine(tx(ax), ty(ay), tx(bx), ty(by), paint)
            }
        }

        val title = buildString {
            append("方案 ${snapshot.documentId.ifEmpty { "—" }}")
            if (snapshot.storeyHeightMm > 0) append("  层高 ${snapshot.storeyHeightMm.toInt()}mm")
            val room = snapshot.rooms.firstOrNull()
            if (room != null) {
                append("  ${room.name.ifEmpty { room.id }}")
                room.clearHeightMm?.let { append(" 净高 ${it.toInt()}mm") }
            }
        }
        canvas.drawText(title, 16f, 36f, labelPaint)

        val legend = "墙 · 门洞 · 窗洞 · 垭口  ${snapshot.walls.size}墙 ${snapshot.openingCount}洞"
        canvas.drawText(legend, 16f, height - 16f, labelPaint)
    }
}
