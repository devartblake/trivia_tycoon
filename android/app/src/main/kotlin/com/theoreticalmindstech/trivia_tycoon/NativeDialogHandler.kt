package com.theoreticalmindstech.trivia_tycoon

import android.app.AlertDialog
import android.content.Context
import android.widget.EditText
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeDialogHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "showInputDialog") {
            val title = call.argument<String>("title") ?: "Title"
            val message = call.argument<String>("message") ?: "Enter text"

            val input = EditText(context)
            val dialog = AlertDialog.Builder(context)
                .setTitle(title)
                .setMessage(message)
                .setView(input)
                .setPositiveButton("OK") { _, _ -> result.success(input.text.toString()) }
                .setNegativeButton("Cancel") { _, _ -> result.success(null) }
                .create()

            dialog.show()
        } else {
            result.notImplemented()
        }
    }
}