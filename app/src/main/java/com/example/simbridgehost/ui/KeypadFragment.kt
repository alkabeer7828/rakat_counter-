package com.example.simbridgehost.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.example.simbridgehost.CallHelper
import com.example.simbridgehost.R
import com.example.simbridgehost.ServerStatusHost
import com.example.simbridgehost.BridgeServerService
import com.example.simbridgehost.databinding.FragmentKeypadBinding

class KeypadFragment : Fragment() {

    private var _binding: FragmentKeypadBinding? = null
    private val binding get() = _binding!!

    private val dialedNumber = StringBuilder()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentKeypadBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.btnStartServer.setOnClickListener {
            (activity as? ServerStatusHost)?.requestPermissionsAndStartServer()
        }

        binding.btnDefaultDialer.setOnClickListener {
            (activity as? ServerStatusHost)?.requestDefaultDialerRole()
        }

        setupDialPad()
        updateDialDisplay()
        refreshUi()
    }

    override fun onResume() {
        super.onResume()
        refreshUi()
    }

    private fun updateServerStatus() {
        if (_binding == null) return
        val host = activity as? ServerStatusHost
        val running = host?.isServerRunning() == true

        binding.tvServerStatus.text = if (running) {
            getString(R.string.status_running, BridgeServerService.SERVER_PORT)
        } else {
            getString(R.string.status_stopped)
        }

        binding.tvEndpoint.text = getString(
            R.string.endpoint_info,
            BridgeServerService.SERVER_PORT
        )
    }

    fun refreshUi() {
        updateServerStatus()
        updateDefaultDialerButton()
    }

    fun setDialNumber(number: String) {
        dialedNumber.clear()
        dialedNumber.append(number)
        updateDialDisplay()
    }

    private fun updateDefaultDialerButton() {
        val host = activity as? ServerStatusHost ?: return
        if (host.isDefaultDialer()) {
            binding.btnDefaultDialer.text = getString(R.string.default_dialer_set)
            binding.btnDefaultDialer.isEnabled = false
        } else {
            binding.btnDefaultDialer.text = getString(R.string.request_default_dialer)
            binding.btnDefaultDialer.isEnabled = true
        }
    }

    private fun setupDialPad() {
        val keyMap = mapOf(
            binding.btnKey0 to "0",
            binding.btnKey1 to "1",
            binding.btnKey2 to "2",
            binding.btnKey3 to "3",
            binding.btnKey4 to "4",
            binding.btnKey5 to "5",
            binding.btnKey6 to "6",
            binding.btnKey7 to "7",
            binding.btnKey8 to "8",
            binding.btnKey9 to "9",
            binding.btnKeyStar to "*",
            binding.btnKeyHash to "#"
        )

        keyMap.forEach { (button, digit) ->
            button.setOnClickListener { appendDigit(digit) }
        }

        binding.btnBackspace.setOnClickListener { removeLastDigit() }

        binding.btnCall.setOnClickListener {
            CallHelper.placeCall(requireContext(), dialedNumber.toString())
        }
    }

    private fun appendDigit(digit: String) {
        dialedNumber.append(digit)
        updateDialDisplay()
    }

    private fun removeLastDigit() {
        if (dialedNumber.isNotEmpty()) {
            dialedNumber.deleteCharAt(dialedNumber.length - 1)
            updateDialDisplay()
        }
    }

    private fun updateDialDisplay() {
        binding.tvDialNumber.text = dialedNumber.toString()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
