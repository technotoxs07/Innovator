package com.innovation.innovator

import android.app.Service
import android.content.Intent
import android.os.Bundle
import android.os.IBinder

class CallService : Service() {
    // onBind returns null since this is not a bound service
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Extract call data from the incoming intent (immutable reference, but object can be mutated if needed)
        val callData: Bundle? = intent?.extras

        // Create an intent to launch MainActivity
        val activityIntent = Intent(this, MainActivity::class.java).apply {
            // Set flags to create a new task or bring an existing MainActivity to the front
            this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            // Set a custom action to indicate an incoming call
            action = "INCOMING_CALL"
            // Add call data to the intent if it exists (safe pass-through)
            callData?.let { putExtras(it) }  // No reassignment here; if modifying, see notes
        }

        // Launch MainActivity with the call data
        startActivity(activityIntent)

        // Return START_NOT_STICKY to indicate the service should not be restarted if killed
        return START_NOT_STICKY
    }
}