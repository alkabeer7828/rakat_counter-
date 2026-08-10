package com.example.simbridgehost

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.core.content.ContextCompat

object CallHelper {

    fun placeCall(context: Context, number: String) {
        val trimmed = number.trim()
        if (trimmed.isEmpty()) {
            Toast.makeText(context, R.string.enter_number, Toast.LENGTH_SHORT).show()
            return
        }

        val intent = Intent(Intent.ACTION_CALL).apply {
            data = Uri.parse("tel:$trimmed")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        ContextCompat.startActivity(context, intent, null)
    }
}
