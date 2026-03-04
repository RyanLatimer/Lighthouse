/**
 * Shared IndexedDB helper for the Lighthouse offline subsystem.
 *
 * Every Stimulus controller that touches IndexedDB should import from here
 * so the database name, version, and object-store creation logic live in a
 * single place. Bumping DB_VERSION or adding a new store only needs to
 * happen here.
 *
 * IMPORTANT: The service worker (app/views/pwa/service-worker.js.erb) has
 * its own duplicate of DB_NAME, DB_VERSION, and the object store creation
 * logic because service workers cannot import ES modules. When changing
 * these values, update both files.
 */

export const DB_NAME = "lighthouse"
export const DB_VERSION = 3
export const SCOUTING_STORE = "offline_entries"
export const PIT_STORE = "offline_pit_entries"
export const EVENT_DATA_STORE = "event_data"

export function openDB() {
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
      if (!db.objectStoreNames.contains(EVENT_DATA_STORE)) {
        db.createObjectStore(EVENT_DATA_STORE, { keyPath: "event_id" })
      }
    }

    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error)
  })
}
