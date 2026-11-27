package `in`.hooplock.agent.ui

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import `in`.hooplock.agent.R

/** Tiny view helpers so screens need no layout XML or AppCompat. */
internal object Ui {
    const val BRAND = 0xFFFF5A0A.toInt()
    const val INK = 0xFF1C1C1E.toInt()
    const val MUTED = 0xFF6B7280.toInt()

    fun dp(ctx: Context, v: Int) = (v * ctx.resources.displayMetrics.density).toInt()

    fun column(ctx: Context, padding: Int = 20): LinearLayout = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(ctx, padding), dp(ctx, padding), dp(ctx, padding), dp(ctx, padding))
    }

    fun scroll(ctx: Context, child: View) = ScrollView(ctx).apply { isFillViewport = true; addView(child) }

    fun text(ctx: Context, s: CharSequence, size: Float = 16f, color: Int = INK, bold: Boolean = false, center: Boolean = false) =
        TextView(ctx).apply {
            text = s; textSize = size; setTextColor(color)
            if (bold) setTypeface(typeface, Typeface.BOLD)
            if (center) gravity = Gravity.CENTER_HORIZONTAL
            setPadding(0, dp(ctx, 4), 0, dp(ctx, 4))
        }

    fun button(ctx: Context, label: String, style: Int = 0, onClick: () -> Unit) = Button(ctx).apply {
        text = label; isAllCaps = false; textSize = 17f
        setTypeface(typeface, Typeface.BOLD)
        setBackgroundResource(when (style) { 1 -> R.drawable.btn_outline; 2 -> R.drawable.btn_danger; else -> R.drawable.btn_primary })
        setTextColor(if (style == 1) BRAND else Color.WHITE)
        minHeight = dp(ctx, 54)
        setOnClickListener { onClick() }
        layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(ctx, 10)
        }
    }

    fun card(ctx: Context) = column(ctx, 16).apply {
        setBackgroundResource(R.drawable.card)
        layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(ctx, 12)
        }
    }

    fun qr(content: String, size: Int): Bitmap {
        val m = QRCodeWriter().encode(content, BarcodeFormat.QR_CODE, size, size)
        val px = IntArray(size * size) { i -> if (m[i % size, i / size]) Color.BLACK else Color.WHITE }
        return Bitmap.createBitmap(px, size, size, Bitmap.Config.RGB_565)
    }

    fun rupees(v: Double): String = if (v % 1.0 == 0.0) "%,.0f".format(v) else "%,.2f".format(v)
}
