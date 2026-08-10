package com.example.simbridgehost.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.provider.Telephony
import android.telephony.SmsManager
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.simbridgehost.R
import com.example.simbridgehost.adapter.SmsAdapter
import com.example.simbridgehost.databinding.FragmentMessagesBinding
import com.example.simbridgehost.model.SmsEntry

class MessagesFragment : Fragment() {

    private var _binding: FragmentMessagesBinding? = null
    private val binding get() = _binding!!

    private lateinit var adapter: SmsAdapter

    private val readPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            loadMessages()
        } else {
            showEmpty(getString(R.string.permission_required))
        }
    }

    private val sendPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            sendSms()
        } else {
            Toast.makeText(requireContext(), R.string.permission_required, Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMessagesBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        adapter = SmsAdapter()
        binding.recyclerMessages.layoutManager = LinearLayoutManager(requireContext())
        binding.recyclerMessages.adapter = adapter

        binding.btnSendSms.setOnClickListener { ensureSendPermissionAndSend() }
    }

    override fun onResume() {
        super.onResume()
        ensureReadPermissionAndLoad()
    }

    private fun ensureReadPermissionAndLoad() {
        when {
            ContextCompat.checkSelfPermission(
                requireContext(),
                Manifest.permission.READ_SMS
            ) == PackageManager.PERMISSION_GRANTED -> loadMessages()

            else -> readPermissionLauncher.launch(Manifest.permission.READ_SMS)
        }
    }

    private fun ensureSendPermissionAndSend() {
        when {
            ContextCompat.checkSelfPermission(
                requireContext(),
                Manifest.permission.SEND_SMS
            ) == PackageManager.PERMISSION_GRANTED -> sendSms()

            else -> sendPermissionLauncher.launch(Manifest.permission.SEND_SMS)
        }
    }

    private fun loadMessages() {
        val entries = mutableListOf<SmsEntry>()

        val cursor = requireContext().contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf(
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE
            ),
            null,
            null,
            "${Telephony.Sms.DATE} DESC"
        )

        cursor?.use {
            val addressIndex = it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val bodyIndex = it.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val dateIndex = it.getColumnIndexOrThrow(Telephony.Sms.DATE)

            while (it.moveToNext()) {
                entries.add(
                    SmsEntry(
                        address = it.getString(addressIndex).orEmpty(),
                        body = it.getString(bodyIndex).orEmpty(),
                        dateMillis = it.getLong(dateIndex)
                    )
                )
            }
        }

        adapter.submitList(entries)
        if (entries.isEmpty()) {
            showEmpty(getString(R.string.no_messages))
        } else {
            binding.tvEmpty.visibility = View.GONE
            binding.recyclerMessages.visibility = View.VISIBLE
        }
    }

    private fun sendSms() {
        val number = binding.etSmsNumber.text?.toString()?.trim().orEmpty()
        val message = binding.etSmsMessage.text?.toString()?.trim().orEmpty()

        if (number.isEmpty()) {
            Toast.makeText(requireContext(), R.string.enter_number, Toast.LENGTH_SHORT).show()
            return
        }

        if (message.isEmpty()) {
            Toast.makeText(requireContext(), R.string.sms_message_hint, Toast.LENGTH_SHORT).show()
            return
        }

        try {
            SmsManager.getDefault().sendTextMessage(number, null, message, null, null)
            Toast.makeText(requireContext(), R.string.sms_sent, Toast.LENGTH_SHORT).show()
            binding.etSmsMessage.text?.clear()
            loadMessages()
        } catch (e: Exception) {
            Toast.makeText(requireContext(), R.string.sms_failed, Toast.LENGTH_SHORT).show()
        }
    }

    private fun showEmpty(message: String) {
        binding.tvEmpty.text = message
        binding.tvEmpty.visibility = View.VISIBLE
        binding.recyclerMessages.visibility = View.GONE
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
