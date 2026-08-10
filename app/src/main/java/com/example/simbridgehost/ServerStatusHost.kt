package com.example.simbridgehost

interface ServerStatusHost {
    fun requestPermissionsAndStartServer()
    fun requestDefaultDialerRole()
    fun isDefaultDialer(): Boolean
    fun isServerRunning(): Boolean
}
