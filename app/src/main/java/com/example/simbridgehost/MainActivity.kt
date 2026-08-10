package com.example.simbridgehost

import android.Manifest
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.telecom.TelecomManager
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.example.simbridgehost.databinding.ActivityMainBinding
import com.example.simbridgehost.ui.ContactsFragment
import com.example.simbridgehost.ui.KeypadFragment
import com.example.simbridgehost.ui.MessagesFragment
import com.example.simbridgehost.ui.RecentsFragment
import com.google.android.material.navigation.NavigationBarView

class MainActivity : AppCompatActivity(), ServerStatusHost {

    private lateinit var binding: ActivityMainBinding
    private var serviceRunning = false

    private lateinit var keypadFragment: KeypadFragment
    private lateinit var recentsFragment: RecentsFragment
    private lateinit var contactsFragment: ContactsFragment
    private lateinit var messagesFragment: MessagesFragment

    private lateinit var activeFragment: Fragment

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            serviceRunning = true
            notifyKeypadStatusChanged()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            serviceRunning = false
            notifyKeypadStatusChanged()
        }
    }

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { results ->
        val denied = results.filterValues { !it }.keys
        if (denied.isEmpty()) {
            startBridgeService()
        } else {
            Toast.makeText(
                this,
                "Required permissions denied: ${denied.joinToString()}",
                Toast.LENGTH_LONG
            ).show()
            notifyKeypadStatusChanged()
        }
    }

    private val dialerRoleLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        notifyKeypadStatusChanged()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        Toast.makeText(this, "MainActivity onCreate ran", Toast.LENGTH_LONG).show()

        if (savedInstanceState == null) {
            keypadFragment = KeypadFragment()
            recentsFragment = RecentsFragment()
            contactsFragment = ContactsFragment()
            messagesFragment = MessagesFragment()

            supportFragmentManager.beginTransaction()
                .add(R.id.fragment_container, messagesFragment, TAG_MESSAGES)
                .hide(messagesFragment)
                .add(R.id.fragment_container, contactsFragment, TAG_CONTACTS)
                .hide(contactsFragment)
                .add(R.id.fragment_container, recentsFragment, TAG_RECENTS)
                .hide(recentsFragment)
                .add(R.id.fragment_container, keypadFragment, TAG_KEYPAD)
                .commit()

            activeFragment = keypadFragment
        } else {
            keypadFragment = supportFragmentManager.findFragmentByTag(TAG_KEYPAD) as KeypadFragment
            recentsFragment = supportFragmentManager.findFragmentByTag(TAG_RECENTS) as RecentsFragment
            contactsFragment = supportFragmentManager.findFragmentByTag(TAG_CONTACTS) as ContactsFragment
            messagesFragment = supportFragmentManager.findFragmentByTag(TAG_MESSAGES) as MessagesFragment
            activeFragment = supportFragmentManager.fragments.firstOrNull { !it.isHidden } ?: keypadFragment
        }

        binding.bottomNavigation.setOnItemSelectedListener(
            NavigationBarView.OnItemSelectedListener { item ->
                when (item.itemId) {
                    R.id.nav_keypad -> showFragment(keypadFragment)
                    R.id.nav_recents -> showFragment(recentsFragment)
                    R.id.nav_contacts -> showFragment(contactsFragment)
                    R.id.nav_messages -> showFragment(messagesFragment)
                    else -> false
                }
            }
        )

        binding.bottomNavigation.selectedItemId = R.id.nav_keypad
        handleDialIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDialIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        bindToServiceIfRunning()
    }

    override fun onStop() {
        super.onStop()
        try {
            unbindService(serviceConnection)
        } catch (_: IllegalArgumentException) {
            // Service was not bound
        }
    }

    override fun requestPermissionsAndStartServer() {
        Toast.makeText(this, "requestPermissionsAndStartServer CALLED", Toast.LENGTH_LONG).show()
        val permissions = buildServerPermissions()
        val missing = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missing.isEmpty()) {
            startBridgeService()
        } else {
            permissionLauncher.launch(missing.toTypedArray())
        }
    }

    override fun requestDefaultDialerRole() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            if (roleManager.isRoleAvailable(RoleManager.ROLE_DIALER) &&
                !roleManager.isRoleHeld(RoleManager.ROLE_DIALER)
            ) {
                dialerRoleLauncher.launch(
                    roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                )
                return
            }
        }

        val telecomManager = getSystemService(TelecomManager::class.java)
        if (packageName != telecomManager.defaultDialerPackage) {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            }
            dialerRoleLauncher.launch(intent)
        }
    }

    override fun isDefaultDialer(): Boolean {
        val telecomManager = getSystemService(TelecomManager::class.java)
        return packageName == telecomManager.defaultDialerPackage
    }

    override fun isServerRunning(): Boolean = serviceRunning

    private fun showFragment(fragment: Fragment): Boolean {
        if (fragment == activeFragment) return true

        supportFragmentManager.beginTransaction()
            .hide(activeFragment)
            .show(fragment)
            .commit()

        activeFragment = fragment
        return true
    }

    private fun handleDialIntent(intent: Intent?) {
        val data = intent?.data ?: return
        if (data.scheme != "tel") return

        binding.bottomNavigation.selectedItemId = R.id.nav_keypad
        showFragment(keypadFragment)

        val number = data.schemeSpecificPart.orEmpty()
        if (number.isNotEmpty()) {
            keypadFragment.setDialNumber(number)
        }
    }

    private fun buildServerPermissions(): List<String> {
        val permissions = mutableListOf(
            Manifest.permission.CALL_PHONE,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.MODIFY_AUDIO_SETTINGS,
            Manifest.permission.INTERNET,
            Manifest.permission.ACCESS_WIFI_STATE,
            Manifest.permission.ACCESS_NETWORK_STATE
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            permissions.add(Manifest.permission.ANSWER_PHONE_CALLS)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        return permissions
    }

    private fun startBridgeService() {
        Toast.makeText(this, "startBridgeService() CALLED", Toast.LENGTH_LONG).show()
        val intent = Intent(this, BridgeServerService::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }

        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
        serviceRunning = true
        notifyKeypadStatusChanged()
        Toast.makeText(this, R.string.server_started, Toast.LENGTH_SHORT).show()
    }

    private fun bindToServiceIfRunning() {
        val intent = Intent(this, BridgeServerService::class.java)
        bindService(intent, serviceConnection, 0)
    }

    private fun notifyKeypadStatusChanged() {
        if (::keypadFragment.isInitialized) {
            keypadFragment.refreshUi()
        }
    }

    companion object {
        private const val TAG_KEYPAD = "keypad"
        private const val TAG_RECENTS = "recents"
        private const val TAG_CONTACTS = "contacts"
        private const val TAG_MESSAGES = "messages"
    }
}