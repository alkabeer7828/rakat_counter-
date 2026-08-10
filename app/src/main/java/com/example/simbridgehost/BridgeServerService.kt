package com.example.simbridgehost

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.telecom.Call
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationCompat
import io.ktor.server.application.install
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.routing.routing
import io.ktor.server.websocket.WebSockets
import io.ktor.server.websocket.webSocket
import io.ktor.websocket.Frame
import io.ktor.websocket.readText
import io.ktor.server.websocket.DefaultWebSocketServerSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.CopyOnWriteArrayList

class BridgeServerService : Service() {

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var serverStarted = false

    private val sessions = CopyOnWriteArrayList<DefaultWebSocketServerSession>()
    private var currentCall: Call? = null

    // Live signal levels per SIM slot (0-4), updated by TelephonyCallback
    private val signalLevels = mutableMapOf<Int, Int>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.i(TAG, "BridgeServerService onCreate - instance set: ${instance != null}")
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this, "BridgeServerService STARTED", Toast.LENGTH_LONG).show()
        }
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification("Starting server…"))

        if (!serverStarted) {
            serverStarted = true
            startWebSocketServer()
            startStatusBroadcastLoop()
            registerSignalListeners()
        }

        updateNotification("Running on port $SERVER_PORT")
        return START_STICKY
    }

    override fun onDestroy() {
        serviceScope.cancel()
        serverStarted = false
        if (instance === this) {
            instance = null
        }
        super.onDestroy()
    }

    private fun startWebSocketServer() {
        serviceScope.launch {
            try {
                embeddedServer(Netty, port = SERVER_PORT, host = "0.0.0.0") {
                    install(WebSockets) {
                        pingPeriodMillis = 15_000
                        timeoutMillis = 30_000
                    }

                    routing {
                        webSocket("/callstream") {
                            Log.i(TAG, "WebSocket client connected")
                            sessions.add(this)

                            // Send an immediate status snapshot on connect
                            try {
                                send(Frame.Text(buildStatusPayload().toString()))
                            } catch (e: Exception) {
                                Log.e(TAG, "Failed to send initial status", e)
                            }

                            try {
                                for (frame in incoming) {
                                    if (frame is Frame.Text) {
                                        handleMessage(frame.readText())
                                    }
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "WebSocket session error", e)
                            } finally {
                                sessions.remove(this)
                                Log.i(TAG, "WebSocket client disconnected")
                            }
                        }
                    }
                }.start(wait = true)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start WebSocket server", e)
                updateNotification("Server error: ${e.message}")
            }
        }
    }

    /** Periodically pushes device status (SIM info + battery) to all connected clients. */
    private fun startStatusBroadcastLoop() {
        serviceScope.launch {
            while (true) {
                if (sessions.isNotEmpty()) {
                    val payload = buildStatusPayload()
                    sessions.forEach { session ->
                        try {
                            session.send(Frame.Text(payload.toString()))
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to broadcast status", e)
                        }
                    }
                }
                delay(5000)
            }
        }
    }

    private fun buildStatusPayload(): JSONObject {
        val json = JSONObject()
        json.put("type", "STATUS")
        json.put("battery", getBatteryPercent())
        json.put("sims", getSimInfoArray())
        return json
    }

    private fun getBatteryPercent(): Int {
        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun getSimInfoArray(): JSONArray {
        val array = JSONArray()
        try {
            val subscriptionManager =
                getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager

            val activeSubs = subscriptionManager.activeSubscriptionInfoList ?: emptyList()

            for (sub in activeSubs) {
                val slotIndex = sub.simSlotIndex // 0-based
                val simEntry = JSONObject()
                simEntry.put("slot", slotIndex + 1) // Display as 1 or 2
                simEntry.put("carrier", sub.carrierName?.toString() ?: "Unknown")
                simEntry.put("signalLevel", signalLevels[slotIndex] ?: -1)
                array.put(simEntry)
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing permission for SIM info", e)
        }
        return array
    }

    /**
     * Registers a signal-strength listener per active SIM slot so we can
     * report real bar levels (0-4) instead of a static value.
     */
    private fun registerSignalListeners() {
        try {
            val subscriptionManager =
                getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val activeSubs = subscriptionManager.activeSubscriptionInfoList ?: emptyList()

            for (sub in activeSubs) {
                val slotIndex = sub.simSlotIndex
                val tm = (getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager)
                    .createForSubscriptionId(sub.subscriptionId)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    tm.registerTelephonyCallback(
                        mainExecutor,
                        object : android.telephony.TelephonyCallback(),
                            android.telephony.TelephonyCallback.SignalStrengthsListener {
                            override fun onSignalStrengthsChanged(signalStrength: android.telephony.SignalStrength) {
                                signalLevels[slotIndex] = signalStrength.level
                            }
                        }
                    )
                } else {
                    @Suppress("DEPRECATION")
                    tm.listen(object : android.telephony.PhoneStateListener() {
                        @Suppress("DEPRECATION")
                        override fun onSignalStrengthsChanged(signalStrength: android.telephony.SignalStrength) {
                            signalLevels[slotIndex] = signalStrength.level
                        }
                    }, android.telephony.PhoneStateListener.LISTEN_SIGNAL_STRENGTHS)
                }
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing permission for signal listeners", e)
        }
    }

    private fun handleMessage(text: String) {
        Log.d(TAG, "Received: $text")

        try {
            val json = JSONObject(text)
            val action = json.optString("action")
            val number = json.optString("number")

            when (action.uppercase()) {
                "DIAL" -> {
                    if (number.isNotBlank()) {
                        placeCall(number)
                    } else {
                        Log.w(TAG, "DIAL action missing number")
                    }
                }
                "ANSWER" -> answerCurrentCall()
                "HANGUP" -> hangUpCurrentCall()
                else -> Log.w(TAG, "Unknown action: $action")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse message", e)
        }
    }

    private fun placeCall(number: String) {
        val intent = Intent(Intent.ACTION_CALL).apply {
            data = Uri.parse("tel:$number")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
        Log.i(TAG, "Placing call to $number")
    }

    private fun answerCurrentCall() {
        currentCall?.answer(0)
        Log.i(TAG, "Answering current call")
    }

    private fun hangUpCurrentCall() {
        currentCall?.disconnect()
        Log.i(TAG, "Hanging up current call")
    }

    fun broadcastCallState(state: String, number: String) {
        val payload = JSONObject().apply {
            put("type", "CALL_STATE")
            put("state", state)
            put("number", number)
        }.toString()

        serviceScope.launch {
            sessions.forEach { session ->
                try {
                    session.send(Frame.Text(payload))
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to send to a session", e)
                }
            }
        }
        Log.i(TAG, "Broadcasted call state: $payload")
    }

    fun registerActiveCall(call: Call?) {
        currentCall = call
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Bridge Server",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "SimBridge WebSocket server status"
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(contentText: String): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(contentText)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(contentText: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, buildNotification(contentText))
    }

    companion object {
        private const val TAG = "BridgeServerService"
        const val SERVER_PORT = 8080
        private const val CHANNEL_ID = "bridge_server_channel"
        private const val NOTIFICATION_ID = 1001

        var instance: BridgeServerService? = null
            private set
    }
}