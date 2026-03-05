import { Controller } from "@hotwired/stimulus"
import { openDB, SCOUTING_STORE, PIT_STORE } from "lib/lighthouse_db"

/**
 * Manages the offline connectivity toast, sync queue count,
 * progress reporting, and failed entry details.
 */
export default class extends Controller {
  static targets = [
    "banner", "status", "queueCount",
    "progress", "progressBar", "progressText",
    "details", "detailsList"
  ]

  connect() {
    this._onOnline = () => this.#goOnline()
    this._onOffline = () => this.#goOffline()
    this._onMessage = (event) => this.#handleSwMessage(event)
    this._onSyncComplete = () => this.#updateQueueCount()
    this._onEntryQueued = () => this.#updateQueueCount()

    window.addEventListener("online", this._onOnline)
    window.addEventListener("offline", this._onOffline)
    window.addEventListener("lighthouse:sync-complete", this._onSyncComplete)
    window.addEventListener("lighthouse:entry-queued", this._onEntryQueued)
    navigator.serviceWorker?.addEventListener("message", this._onMessage)

    if (navigator.onLine) {
      this.#goOnline()
    } else {
      this.#goOffline()
    }

    this.#updateQueueCount()
  }

  disconnect() {
    window.removeEventListener("online", this._onOnline)
    window.removeEventListener("offline", this._onOffline)
    window.removeEventListener("lighthouse:sync-complete", this._onSyncComplete)
    window.removeEventListener("lighthouse:entry-queued", this._onEntryQueued)
    navigator.serviceWorker?.removeEventListener("message", this._onMessage)
    if (this._autoDismissTimeout) clearTimeout(this._autoDismissTimeout)
    if (this._prefetchBannerTimeout) clearTimeout(this._prefetchBannerTimeout)
  }

  // --- Actions ---

  async retrySync() {
    if (!navigator.onLine) return

    this.#showSyncing()

    try {
      const reg = await navigator.serviceWorker?.ready
      if (reg?.sync) {
        await reg.sync.register("sync-scouting-entries")
        await reg.sync.register("sync-pit-scouting-entries")
      }
    } catch {
      // Background sync not available
    }

    setTimeout(() => this.#updateQueueCount(), 3000)
  }

  toggleDetails() {
    if (this.hasDetailsTarget) {
      this.detailsTarget.classList.toggle("hidden")
      if (!this.detailsTarget.classList.contains("hidden")) {
        this.#populateDetails()
      }
    }
  }

  async clearFailed() {
    try {
      const db = await openDB()

      try {
        for (const storeName of [SCOUTING_STORE, PIT_STORE]) {
          if (!db.objectStoreNames.contains(storeName)) continue

          const tx = db.transaction(storeName, "readwrite")
          const store = tx.objectStore(storeName)

          const entries = await new Promise((resolve, reject) => {
            const req = store.getAll()
            req.onsuccess = () => resolve(req.result)
            req.onerror = () => reject(req.error)
          })

          for (const entry of entries) {
            if (entry._syncFailed) {
              store.delete(entry.client_uuid)
            }
          }

          await new Promise((resolve, reject) => {
            tx.oncomplete = resolve
            tx.onerror = () => reject(tx.error)
          })
        }
      } finally {
        db.close()
      }

      this.#updateQueueCount()

      if (this.hasDetailsTarget) {
        this.#populateDetails()
      }
    } catch (error) {
      console.error("[Lighthouse] Failed to clear failed entries:", error)
    }
  }

  // --- Private ---

  #showBanner() {
    if (!this.hasBannerTarget) return
    const el = this.bannerTarget
    el.classList.remove("hidden")
    el.style.opacity = "0"
    el.style.transform = "translateX(-1rem)"
    el.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"

    requestAnimationFrame(() => {
      el.style.opacity = "1"
      el.style.transform = "translateX(0)"
    })
  }

  #hideBanner() {
    if (!this.hasBannerTarget) return
    const el = this.bannerTarget

    el.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
    el.style.opacity = "0"
    el.style.transform = "translateX(-1rem)"

    setTimeout(() => {
      el.classList.add("hidden")
      el.style.opacity = ""
      el.style.transform = ""
      if (this.hasDetailsTarget) {
        this.detailsTarget.classList.add("hidden")
      }
    }, 200)
  }

  #autoDismissAfter(ms) {
    if (this._autoDismissTimeout) clearTimeout(this._autoDismissTimeout)
    this._autoDismissTimeout = setTimeout(() => {
      this._autoDismissTimeout = null
      this.#updateQueueCount()
    }, ms)
  }

  #goOnline() {
    this.#hideProgress()
    this.#updateQueueCount()
  }

  #goOffline() {
    this.#showBanner()
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "You are offline"
    }
    this.#hideProgress()
  }

  #showSyncing() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Syncing..."
    }
    if (this.hasProgressTarget) {
      this.progressTarget.classList.remove("hidden")
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "0%"
    }
  }

  #hideProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.classList.add("hidden")
    }
  }

  #handleSwMessage(event) {
    const data = event.data
    if (!data) return

    if (data.type === "sync-progress") {
      this.#handleSyncProgress(data)
    } else if (data.type === "sync-complete") {
      this.#handleSyncComplete(data)
    } else if (data.type === "prefetch-progress") {
      this.#handlePrefetchProgress(data)
    } else if (data.type === "prefetch-complete") {
      this.#handlePrefetchComplete(data)
    }
  }

  #handleSyncProgress(data) {
    if (data.phase === "start") {
      this.#showBanner()
      this.#showSyncing()
      if (this.hasProgressTextTarget) {
        this.progressTextTarget.textContent = `Syncing ${data.total} ${data.total === 1 ? "entry" : "entries"}...`
      }
    } else if (data.phase === "error") {
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = "Sync error"
      }
      this.#hideProgress()
      this.#updateQueueCount()
    }
  }

  #handleSyncComplete(data) {
    this.#hideProgress()

    if (data.synced > 0 || data.failed > 0) {
      const storeName = data.store === SCOUTING_STORE ? "match" : "pit"

      if (this.hasStatusTarget) {
        if (data.failed > 0) {
          this.statusTarget.textContent = `${data.synced} ${storeName} synced, ${data.failed} failed`
        } else {
          this.statusTarget.textContent = `${data.synced} ${storeName} ${data.synced === 1 ? "entry" : "entries"} synced`
        }
      }
    }

    this._lastSyncResult = {
      ...this._lastSyncResult,
      [data.store]: { synced: data.synced, failed: data.failed, total: data.total, at: new Date().toISOString() }
    }

    this.#updateQueueCount()
  }

  async #updateQueueCount() {
    try {
      const db = await openDB()
      let total = 0
      let pendingCount = 0
      let failedCount = 0

      try {
        for (const storeName of [SCOUTING_STORE, PIT_STORE]) {
          if (!db.objectStoreNames.contains(storeName)) continue

          const entries = await new Promise((resolve, reject) => {
            const tx = db.transaction(storeName, "readonly")
            const req = tx.objectStore(storeName).getAll()
            req.onsuccess = () => resolve(req.result)
            req.onerror = () => reject(req.error)
          })

          for (const entry of entries) {
            total++
            if (entry._syncFailed) {
              failedCount++
            } else {
              pendingCount++
            }
          }
        }
      } finally {
        db.close()
      }

      if (this.hasQueueCountTarget) {
        if (total > 0) {
          let text = `${pendingCount} pending`
          if (failedCount > 0) {
            text += `, ${failedCount} failed`
          }
          this.queueCountTarget.textContent = text
          this.queueCountTarget.classList.remove("hidden")
        } else {
          this.queueCountTarget.classList.add("hidden")
        }
      }

      // Show/hide based on queue state
      if (total > 0 && navigator.onLine) {
        this.#showBanner()
        if (this.hasStatusTarget && !this.statusTarget.textContent.includes("Syncing")) {
          if (failedCount > 0 && pendingCount === 0) {
            this.statusTarget.textContent = `${failedCount} failed ${failedCount === 1 ? "entry" : "entries"}`
          } else {
            this.statusTarget.textContent = "Entries queued for sync"
          }
        }
      } else if (total === 0 && navigator.onLine) {
        this.#hideBanner()
      }
    } catch {
      // IndexedDB not available
    }
  }

  async #populateDetails() {
    if (!this.hasDetailsListTarget) return

    try {
      const db = await openDB()
      const items = []

      try {
        for (const storeName of [SCOUTING_STORE, PIT_STORE]) {
          if (!db.objectStoreNames.contains(storeName)) continue

          const entries = await new Promise((resolve, reject) => {
            const tx = db.transaction(storeName, "readonly")
            const req = tx.objectStore(storeName).getAll()
            req.onsuccess = () => resolve(req.result)
            req.onerror = () => reject(req.error)
          })

          const type = storeName === SCOUTING_STORE ? "Match" : "Pit"

          for (const entry of entries) {
            items.push({
              type,
              uuid: entry.client_uuid,
              team: entry.frc_team_id || "?",
              createdAt: entry.created_at,
              failed: entry._syncFailed || false,
              errors: entry._syncErrors || []
            })
          }
        }
      } finally {
        db.close()
      }

      if (items.length === 0) {
        this.detailsListTarget.innerHTML = `
          <li class="text-xs text-gray-500 py-1.5 text-center">No queued entries</li>
        `
        return
      }

      this.detailsListTarget.innerHTML = items.map((item) => {
        const statusClass = item.failed ? "text-red-400" : "text-amber-400"
        const statusLabel = item.failed ? "Failed" : "Pending"
        const time = item.createdAt ? new Date(item.createdAt).toLocaleTimeString() : ""
        const errorMsg = item.errors.length > 0 ? `<div class="text-[10px] text-red-400/70 mt-0.5">${item.errors[0]}</div>` : ""

        return `
          <li class="flex items-center justify-between py-1.5 border-b border-gray-800/50 last:border-0">
            <div class="min-w-0">
              <span class="text-xs font-medium text-gray-300">${item.type}</span>
              <span class="text-xs text-gray-500 ml-1">Team ${item.team}</span>
              <span class="text-[10px] text-gray-600 ml-1">${time}</span>
              ${errorMsg}
            </div>
            <span class="text-[10px] font-medium ${statusClass} shrink-0 ml-2">${statusLabel}</span>
          </li>
        `
      }).join("")
    } catch (error) {
      console.error("[Lighthouse] Failed to populate details:", error)
    }
  }

  #handlePrefetchProgress(_data) {
    // Silenced — prefetch runs in the background without showing the banner.
  }

  #handlePrefetchComplete(_data) {
    // Silenced — prefetch completion does not show a notification.
  }
}
