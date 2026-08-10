package com.example.simbridgehost.adapter

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.example.simbridgehost.databinding.ItemContactBinding
import com.example.simbridgehost.model.ContactEntry

class ContactsAdapter(
    private val onItemClick: (String) -> Unit
) : RecyclerView.Adapter<ContactsAdapter.ViewHolder>() {

    private val items = mutableListOf<ContactEntry>()

    fun submitList(entries: List<ContactEntry>) {
        items.clear()
        items.addAll(entries)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemContactBinding.inflate(
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
        private val binding: ItemContactBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(entry: ContactEntry) {
            binding.tvName.text = entry.name.ifBlank { "Unknown" }
            binding.tvNumber.text = entry.number
            binding.root.setOnClickListener { onItemClick(entry.number) }
        }
    }
}
