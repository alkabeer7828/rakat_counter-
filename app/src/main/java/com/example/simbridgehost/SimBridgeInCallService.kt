package com.example.simbridgehost

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.telecom.Call
import android.telecom.InCallService
import android.util.Log

class SimBridgeInCallService : InCallService() {

    private val activeCalls = mutableSetOf<Call>()
    private var audioTestThread: Thread? = null
    private var audioTestRunning = false

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            val label = stateLabel(state)
            val number = call.details?.handle?.schemeSpecificPart ?: "unknown"
            Log.i(TAG, "Call state changed: $label for $number")
            BridgeServerService.instance?.broadcastCallState(label, number)

            if (state == Call.STATE_ACTIVE) {
                startAudioCaptureTest()
            } else if (state == Call.STATE_DISCONNECTED) {
                stopAudioCaptureTest()
            }
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        activeCalls.add(call)
        call.registerCallback(callCallback)

        val number = call.details?.handle?.schemeSpecificPart ?: "unknown"
        val label = stateLabel(call.state)
        Log.i(TAG, "Call added: $number, state=$label")
        BridgeServerService.instance?.broadcastCallState(label, number)
        BridgeServerService.instance?.registerActiveCall(call)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        activeCalls.remove(call)

        val number = call.details?.handle?.schemeSpecificPart ?: "unknown"
        Log.i(TAG, "Call removed: $number")
        BridgeServerService.instance?.broadcastCallState("DISCONNECTED", number)
        BridgeServerService.instance?.registerActiveCall(null)
        stopAudioCaptureTest()
    }

    /**
     * TEST ONLY: attempts to open an AudioRecord sourced from the live
     * cellular call and logs whether real (non-silent) audio is captured.
     * Does not stream or save anything yet — this is purely a feasibility check.
     */
    private fun startAudioCaptureTest() {
        if (audioTestRunning) return
        audioTestRunning = true

        audioTestThread = Thread {
            try {
                val sampleRate = 8000
                val channelConfig = AudioFormat.CHANNEL_IN_MONO
                val audioFormat = AudioFormat.ENCODING_PCM_16BIT
                val minBufSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

                Log.i(TAG, "AUDIO_TEST: Attempting AudioRecord with VOICE_CALL source, minBufSize=$minBufSize")

                val recorder = AudioRecord(
                    MediaRecorder.AudioSource.VOICE_CALL,
                    sampleRate,
                    channelConfig,
                    audioFormat,
                    minBufSize * 2
                )

                if (recorder.state != AudioRecord.STATE_INITIALIZED) {
                    Log.e(TAG, "AUDIO_TEST: FAILED - AudioRecord did not initialize. State=${recorder.state}")
                    audioTestRunning = false
                    return@Thread
                }

                Log.i(TAG, "AUDIO_TEST: AudioRecord initialized successfully. Starting recording...")
                recorder.startRecording()

                val buffer = ShortArray(minBufSize)
                var samplesChecked = 0
                var nonZeroSamplesFound = 0

                // Read a few chunks over ~2 seconds to check for real audio vs silence
                val startTime = System.currentTimeMillis()
                while (audioTestRunning && (System.currentTimeMillis() - startTime) < 5000) {
                    val read = recorder.read(buffer, 0, buffer.size)
                    if (read > 0) {
                        for (i in 0 until read) {
                            samplesChecked++
                            if (buffer[i] != 0.toShort()) {
                                nonZeroSamplesFound++
                            }
                        }
                    }
                    Thread.sleep(200)
                }

                recorder.stop()
                recorder.release()

                val percentNonZero = if (samplesChecked > 0) (nonZeroSamplesFound * 100 / samplesChecked) else 0
                Log.i(TAG, "AUDIO_TEST: RESULT - Checked $samplesChecked samples, $nonZeroSamplesFound non-zero ($percentNonZero%)")

                if (percentNonZero > 5) {
                    Log.i(TAG, "AUDIO_TEST: *** LIKELY SUCCESS - Real audio data detected! ***")
                } else {
                    Log.w(TAG, "AUDIO_TEST: *** LIKELY SILENCE - No meaningful audio detected ***")
                }

            } catch (e: SecurityException) {
                Log.e(TAG, "AUDIO_TEST: FAILED - SecurityException: ${e.message}", e)
            } catch (e: Exception) {
                Log.e(TAG, "AUDIO_TEST: FAILED - Exception: ${e.message}", e)
            } finally {
                audioTestRunning = false
            }
        }
        audioTestThread?.start()
    }

    private fun stopAudioCaptureTest() {
        audioTestRunning = false
        audioTestThread = null
    }

    private fun stateLabel(state: Int): String = when (state) {
        Call.STATE_NEW -> "NEW"
        Call.STATE_RINGING -> "RINGING"
        Call.STATE_DIALING -> "DIALING"
        Call.STATE_ACTIVE -> "ACTIVE"
        Call.STATE_HOLDING -> "HOLDING"
        Call.STATE_DISCONNECTED -> "DISCONNECTED"
        Call.STATE_CONNECTING -> "CONNECTING"
        Call.STATE_DISCONNECTING -> "DISCONNECTING"
        Call.STATE_SELECT_PHONE_ACCOUNT -> "SELECT_PHONE_ACCOUNT"
        else -> "UNKNOWN($state)"
    }

    companion object {
        private const val TAG = "SimBridgeInCallService"
    }
}