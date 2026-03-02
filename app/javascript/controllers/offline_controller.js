import { Controller } from "@hotwired/stimulus"

const DB_NAME = "scoutrail"
const DB_VERSION = 1
const STORE_NAME = "offline_entries"
const SYNC_URL = "/api/v1/scouting_entries/bulk_sync"

export default class extends Controller {
  connect() {
    this.boundOnline = () => this.#handleOnline()
    this.boundOffline = () => this.#handleOffline()

    window.addEventListener("online", this.boundOnline)
    window.addEventListener("offline", this.boundOffline)

    this.checkConnection()
  }

  disconnect() {
    window.removeEventListener("online", this.boundOnline)
    window.removeEventListener("offline", this.boundOffline)
  }

  checkConnection() {
    if (navigator.onLine) {
      this.#handleOnline()
    } else {
      this.#handleOffline()
    }
  }

  async syncQueue() {
    if (!navigator.onLine) return

    try {
      const db = await this.#openDB()
      const tx = db.transaction(STORE_NAME, "readonly")
      const store = tx.objectStore(STORE_NAME)

      const entries = await new Promise((resolve, reject) => {
        const request = store.getAll()
        request.onsuccess = () => resolve(request.result)
        request.onerror = () => reject(request.error)
      })

      db.close()

      if (entries.length === 0) return

      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

      const response = await fetch(SYNC_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken || "",
          "Accept": "application/json"
        },
        body: JSON.stringify({ entries })
      })

      if (!response.ok) {
        throw new Error(`Sync failed: ${response.status}`)
      }

      const result = await response.json()

      // Remove successfully synced entries from IndexedDB
      const syncedUuids = result.results
        .filter(r => r.status === "created" || r.status === "existing")
        .map(r => r.client_uuid)

      if (syncedUuids.length > 0) {
        await this.#removeSyncedEntries(syncedUuids)
      }

      this.#showSyncBanner(syncedUuids.length)
    } catch (error) {
      console.error("[ScoutRail] Sync failed:", error)
    }
  }

  // --- Private ---

  #handleOnline() {
    this.element.classList.add("hidden")
    this.syncQueue()
  }

  #handleOffline() {
    this.element.classList.remove("hidden")
  }

  #openDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION)
      request.onupgradeneeded = (event) => {
        const db = event.target.result
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME, { keyPath: "client_uuid" })
        }
      }
      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error)
    })
  }

  async #removeSyncedEntries(uuids) {
    const db = await this.#openDB()
    const tx = db.transaction(STORE_NAME, "readwrite")
    const store = tx.objectStore(STORE_NAME)

    for (const uuid of uuids) {
      store.delete(uuid)
    }

    await new Promise((resolve, reject) => {
      tx.oncomplete = resolve
      tx.onerror = () => reject(tx.error)
    })

    db.close()
  }

  #showSyncBanner(count) {
    if (count === 0) return

    const banner = document.createElement("div")
    banner.className = "fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-orange-600 text-white px-6 py-3 rounded-lg shadow-lg font-medium"
    banner.textContent = `Synced ${count} offline ${count === 1 ? "entry" : "entries"} successfully.`
    document.body.appendChild(banner)

    setTimeout(() => {
      banner.style.transition = "opacity 0.5s"
      banner.style.opacity = "0"
      setTimeout(() => banner.remove(), 500)
    }, 4000)
  }
}
