package com.example.simbridgehost.model

data class SmsEntry(
    val address: String,
    val body: String,
    val dateMillis: Long
)
