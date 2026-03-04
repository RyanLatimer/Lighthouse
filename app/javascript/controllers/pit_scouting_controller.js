import { Controller } from "@hotwired/stimulus"
import { openDB, PIT_STORE } from "lib/lighthouse_db"

/**
 * Handles offline form submission for pit scouting entries.
 * When offline, intercepts the form submit, saves the entry to IndexedDB,
 * and shows a confirmation banner. When online, allows normal form submission.
 *
 * Usage:
 *   <form data-controller="pit-scouting" data-action="submit->pit-scouting#submitForm">
 */
export default class extends Controller {
  submitForm(event) {
    if (navigator.onLine) return // Allow normal submission when online

    event.preventDefault()
    this.#saveToOfflineQueue()
  }

  async #saveToOfflineQueue() {
    try {
      const form = this.element
      const formData = new FormData(form)

      // Build the data object from form fields
      const data = {}
      const dataPrefix = "pit_scouting_entry[data]"

      for (const [key, value] of formData.entries()) {
        // Extract data[field_name] entries
        if (key.startsWith(dataPrefix)) {
          const fieldMatch = key.match(/\[data\]\[(\w+)\](\[\])?$/)
          if (fieldMatch) {
            const fieldName = fieldMatch[1]
            const isArray = fieldMatch[2] === "[]"

            if (isArray) {
              if (!data[fieldName]) data[fieldName] = []
              if (value) data[fieldName].push(value)
            } else {
              data[fieldName] = value
            }
          }
        }
      }

      const entry = {
        client_uuid: crypto.randomUUID(),
        frc_team_id: formData.get("pit_scouting_entry[frc_team_id]") || null,
        event_id: formData.get("pit_scouting_entry[event_id]") || this.#extractEventId(),
        organization_id: formData.get("pit_scouting_entry[organization_id]") || null,
        notes: formData.get("pit_scouting_entry[notes]") || "",
        data: data,
        created_at: new Date().toISOString()
      }

      const db = await openDB()
      const tx = db.transaction(PIT_STORE, "readwrite")
      tx.objectStore(PIT_STORE).add(entry)
      await new Promise((resolve, reject) => {
        tx.oncomplete = resolve
        tx.onerror = () => reject(tx.error)
      })

      db.close()

      this.#showOfflineConfirmation()

      // Dispatch event so connectivity controller can update the queue count
      window.dispatchEvent(new CustomEvent("lighthouse:entry-queued"))
    } catch (error) {
      console.error("[Lighthouse] Failed to save pit scouting entry offline:", error)
      alert("Failed to save entry offline. Please try again.")
    }
  }

  #extractEventId() {
    // Try to find event_id from a hidden field or meta tag
    const hiddenField = this.element.querySelector("[name*='event_id']")
    if (hiddenField) return hiddenField.value

    const meta = document.querySelector("meta[name='current-event-id']")
    if (meta) return meta.content

    return null
  }

  #showOfflineConfirmation() {
    const banner = document.createElement("div")
    banner.className = "fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-amber-600 text-white px-6 py-3 rounded-lg shadow-lg font-medium animate-slide-down"
    banner.innerHTML = `
      <div class="flex items-center gap-2">
        <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div>
          <span>Pit scout saved offline. It will sync when you reconnect.</span>
          <span class="block text-xs text-amber-200 mt-0.5">Photos must be added after syncing.</span>
        </div>
      </div>
    `
    document.body.appendChild(banner)

    setTimeout(() => {
      banner.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
      banner.style.opacity = "0"
      banner.style.transform = "translate(-50%, -8px)"
      setTimeout(() => banner.remove(), 300)
    }, 4000)
  }
}
