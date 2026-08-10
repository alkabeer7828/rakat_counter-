package com.example.simbridgehost.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.example.simbridgehost.databinding.ItemSmsBinding
import com.example.simbridgehost.model.SmsEntry

class SmsAdapter : RecyclerView.Adapter<SmsAdapter.ViewHolder>() {

    private val items = mutableListOf<SmsEntry>()

    fun submitList(entries: List<SmsEntry>) {
        items.clear()
        items.addAll(entries)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemSmsBinding.inflate(
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

    class ViewHolder(
        private val binding: ItemSmsBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(entry: SmsEntry) {
            binding.tvSender.text = entry.address.ifBlank { "Unknown" }
            binding.tvBody.text = entry.body
        }
    }
}
