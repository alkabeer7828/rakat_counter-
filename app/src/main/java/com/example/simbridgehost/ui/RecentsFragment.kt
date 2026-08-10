package com.example.simbridgehost.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.provider.CallLog
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.simbridgehost.CallHelper
import com.example.simbridgehost.R
import com.example.simbridgehost.adapter.CallLogAdapter
import com.example.simbridgehost.databinding.FragmentRecentsBinding
import com.example.simbridgehost.model.CallLogEntry

class RecentsFragment : Fragment() {

    private var _binding: FragmentRecentsBinding? = null
    private val binding get() = _binding!!

    private lateinit var adapter: CallLogAdapter

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            loadCallLog()
        } else {
            showEmpty(getString(R.string.permission_required))
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentRecentsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        adapter = CallLogAdapter { number ->
            CallHelper.placeCall(requireContext(), number)
        }

        binding.recyclerRecents.layoutManager = LinearLayoutManager(requireContext())
        binding.recyclerRecents.adapter = adapter
    }

    override fun onResume() {
        super.onResume()
        ensurePermissionAndLoad()
    }

    private fun ensurePermissionAndLoad() {
        when {
            ContextCompat.checkSelfPermission(
                requireContext(),
                Manifest.permission.READ_CALL_LOG
            ) == PackageManager.PERMISSION_GRANTED -> loadCallLog()

            else -> permissionLauncher.launch(Manifest.permission.READ_CALL_LOG)
        }
    }

    private fun loadCallLog() {
        val entries = mutableListOf<CallLogEntry>()

        val cursor = requireContext().contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            arrayOf(
                CallLog.Calls.NUMBER,
                CallLog.Calls.TYPE,
                CallLog.Calls.DATE
            ),
            null,
            null,
            "${CallLog.Calls.DATE} DESC"
        )

        cursor?.use {
            val numberIndex = it.getColumnIndexOrThrow(CallLog.Calls.NUMBER)
            val typeIndex = it.getColumnIndexOrThrow(CallLog.Calls.TYPE)
            val dateIndex = it.getColumnIndexOrThrow(CallLog.Calls.DATE)

            while (it.moveToNext()) {
                entries.add(
                    CallLogEntry(
                        number = it.getString(numberIndex).orEmpty(),
                        callType = it.getInt(typeIndex),
                        dateMillis = it.getLong(dateIndex)
                    )
                )
            }
        }

        adapter.submitList(entries)
        if (entries.isEmpty()) {
            showEmpty(getString(R.string.no_call_log))
        } else {
            binding.tvEmpty.visibility = View.GONE
            binding.recyclerRecents.visibility = View.VISIBLE
        }
    }

    private fun showEmpty(message: String) {
        binding.tvEmpty.text = message
        binding.tvEmpty.visibility = View.VISIBLE
        binding.recyclerRecents.visibility = View.GONE
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
