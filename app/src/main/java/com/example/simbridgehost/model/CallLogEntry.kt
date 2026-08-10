package com.example.simbridgehost.model

data class CallLogEntry(
    val number: String,
    val callType: Int,
    val dateMillis: Long
)
