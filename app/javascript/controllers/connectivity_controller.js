import { Controller } from "@hotwired/stimulus"

const DB_NAME = "scoutrail"
const DB_VERSION = 2
const SCOUTING_STORE = "offline_entries"
const PIT_STORE = "offline_pit_entries"

/**
 * Manages the offline connectivity indicator banner and queue count.
 * Attach to a container element in the layout that wraps the status bar.
 *
 * Targets:
 *   - banner: the offline status bar element
 *   - status: text element showing online/offline status
 *   - queueCount: element showing number of queued entries
 */
export default class extends Controller {
  static targets = ["banner", "status", "queueCount"]

  connect() {
    this._onOnline = () => this.#goOnline()
    this._onOffline = () => this.#goOffline()
    this._onMessage = (event) => this.#handleSwMessage(event)

    window.addEventListener("online", this._onOnline)
    window.addEventListener("offline", this._onOffline)
    navigator.serviceWorker?.addEventListener("message", this._onMessage)

    // Initial check
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
    navigator.serviceWorker?.removeEventListener("message", this._onMessage)
  }

  // --- Actions ---

  async retrySync() {
    if (!navigator.onLine) return

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Syncing..."
    }

    try {
      // Trigger background sync if available
      const reg = await navigator.serviceWorker?.ready
      if (reg?.sync) {
        await reg.sync.register("sync-scouting-entries")
        await reg.sync.register("sync-pit-scouting-entries")
      }
    } catch {
      // Background sync not available, will sync via offline_controller
    }

    // Update count after a short delay
    setTimeout(() => this.#updateQueueCount(), 2000)
  }

  // --- Private ---

  #goOnline() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("hidden")
    }
    this.#updateQueueCount()
  }

  #goOffline() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("hidden")
    }
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "You are offline"
    }
  }

  #handleSwMessage(event) {
    if (event.data?.type === "sync-complete") {
      this.#updateQueueCount()
    }
  }

  async #updateQueueCount() {
    try {
      const db = await this.#openDB()
      let total = 0

      for (const storeName of [SCOUTING_STORE, PIT_STORE]) {
        if (db.objectStoreNames.contains(storeName)) {
          const count = await new Promise((resolve, reject) => {
            const tx = db.transaction(storeName, "readonly")
            const req = tx.objectStore(storeName).count()
            req.onsuccess = () => resolve(req.result)
            req.onerror = () => reject(req.error)
          })
          total += count
        }
      }

      db.close()

      if (this.hasQueueCountTarget) {
        if (total > 0) {
          this.queueCountTarget.textContent = `${total} pending`
          this.queueCountTarget.classList.remove("hidden")
        } else {
          this.queueCountTarget.classList.add("hidden")
        }
      }

      // Show the banner even when online if there are queued entries
      if (total > 0 && navigator.onLine && this.hasBannerTarget) {
        this.bannerTarget.classList.remove("hidden")
        if (this.hasStatusTarget) {
          this.statusTarget.textContent = "Entries queued for sync"
        }
      }
    } catch {
      // IndexedDB not available
    }
  }

  #openDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION)
      request.onupgradeneeded = (event) => {
        const db = event.target.result
        if (!db.objectStoreNames.contains(SCOUTING_STORE)) {
          db.createObjectStore(SCOUTING_STORE, { keyPath: "client_uuid" })
        }
        if (!db.objectStoreNames.contains(PIT_STORE)) {
          db.createObjectStore(PIT_STORE, { keyPath: "client_uuid" })
        }
      }
      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error)
    })
  }
}
