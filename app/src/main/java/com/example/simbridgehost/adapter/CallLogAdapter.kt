package com.example.simbridgehost.adapter

import android.provider.CallLog
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.example.simbridgehost.R
import com.example.simbridgehost.databinding.ItemCallLogBinding
import com.example.simbridgehost.model.CallLogEntry
import java.text.DateFormat
import java.util.Date

class CallLogAdapter(
    private val onItemClick: (String) -> Unit
) : RecyclerView.Adapter<CallLogAdapter.ViewHolder>() {

    private val items = mutableListOf<CallLogEntry>()
    private val dateFormat = DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT)

    fun submitList(entries: List<CallLogEntry>) {
        items.clear()
        items.addAll(entries)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemCallLogBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount(): Int = items.size

    inner class ViewHolder(
        private val binding: ItemCallLogBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(entry: CallLogEntry) {
            binding.tvNumber.text = entry.number.ifBlank { "Unknown" }
            binding.tvCallType.text = callTypeLabel(entry.callType)
            binding.tvDate.text = dateFormat.format(Date(entry.dateMillis))
            binding.root.setOnClickListener { onItemClick(entry.number) }
        }

        private fun callTypeLabel(type: Int): String {
            val context = binding.root.context
            return when (type) {
                CallLog.Calls.INCOMING_TYPE -> context.getString(R.string.call_type_incoming)
                CallLog.Calls.OUTGOING_TYPE -> context.getString(R.string.call_type_outgoing)
                CallLog.Calls.MISSED_TYPE -> context.getString(R.string.call_type_missed)
                else -> context.getString(R.string.call_type_other)
            }
        }
    }
}
