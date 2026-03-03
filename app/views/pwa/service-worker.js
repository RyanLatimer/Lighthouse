const CACHE_VERSION = "lighthouse-v3"

const PRECACHE_URLS = [
  "/",
  "/manifest.json"
]

const DB_NAME = "lighthouse"
const DB_VERSION = 2
const SCOUTING_STORE = "offline_entries"
const PIT_STORE = "offline_pit_entries"
const MAX_SYNC_RETRIES = 3
const RETRY_DELAYS = [1000, 5000, 15000]

// --- Install: precache core shell ---

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => {
      return cache.addAll(PRECACHE_URLS)
    }).then(() => self.skipWaiting())
  )
})

// --- Activate: clean up old caches ---

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys
          .filter((key) => key !== CACHE_VERSION)
          .map((key) => caches.delete(key))
      )
    }).then(() => self.clients.claim())
  )
})

// --- Fetch: strategy varies by request type ---

self.addEventListener("fetch", (event) => {
  const { request } = event
  const url = new URL(request.url)

  // Skip non-GET requests (let POST/PATCH/DELETE go through normally)
  if (request.method !== "GET") return

  // API calls: network-first
  if (url.pathname.startsWith("/api/")) {
    event.respondWith(networkFirst(request))
    return
  }

  // Static assets (JS, CSS, images, fonts): cache-first
  if (isStaticAsset(url.pathname)) {
    event.respondWith(cacheFirst(request))
    return
  }

  // HTML pages: stale-while-revalidate
  event.respondWith(staleWhileRevalidate(request))
})

// --- Caching strategies ---

async function networkFirst(request) {
  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(CACHE_VERSION)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    const cached = await caches.match(request)
    return cached || new Response(JSON.stringify({ error: "offline" }), {
      status: 503,
      headers: { "Content-Type": "application/json" }
    })
  }
}

async function cacheFirst(request) {
  const cached = await caches.match(request)
  if (cached) return cached

  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(CACHE_VERSION)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    return new Response("", { status: 503, statusText: "Offline" })
  }
}

async function staleWhileRevalidate(request) {
  const cached = await caches.match(request)

  const fetchPromise = fetch(request).then((response) => {
    if (response.ok) {
      caches.open(CACHE_VERSION).then((c) => c.put(request, response.clone()))
    }
    return response
  }).catch(() => null)

  return cached || await fetchPromise || offlineFallback()
}

function offlineFallback() {
  return new Response(
    `<!DOCTYPE html>
    <html>
      <head><title>Lighthouse - Offline</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body { font-family: system-ui; background: #111827; color: #f3f4f6; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
        .container { text-align: center; padding: 2rem; }
        h1 { color: #F97316; }
        p { color: #9ca3af; }
      </style></head>
      <body>
        <div class="container">
          <h1>Lighthouse</h1>
          <p>You are currently offline.</p>
          <p>Any scouting entries you submitted are saved and will sync automatically when you reconnect.</p>
        </div>
      </body>
    </html>`,
    { status: 200, headers: { "Content-Type": "text/html" } }
  )
}

// --- Background sync for offline form submissions ---

self.addEventListener("sync", (event) => {
  if (event.tag === "sync-scouting-entries") {
    event.waitUntil(syncOfflineEntries(SCOUTING_STORE, "/api/v1/scouting_entries/bulk_sync"))
  }
  if (event.tag === "sync-pit-scouting-entries") {
    event.waitUntil(syncOfflineEntries(PIT_STORE, "/api/v1/pit_scouting_entries/bulk_sync"))
  }
})

async function syncOfflineEntries(storeName, syncUrl) {
  try {
    const db = await openDB()

    if (!db.objectStoreNames.contains(storeName)) {
      db.close()
      return
    }

    const tx = db.transaction(storeName, "readonly")
    const store = tx.objectStore(storeName)

    const entries = await new Promise((resolve, reject) => {
      const request = store.getAll()
      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error)
    })

    db.close()

    // Filter out entries already marked as permanently failed
    const toSync = entries.filter((e) => !e._syncFailed)
    if (toSync.length === 0) return

    // Notify clients that sync is starting
    await notifyClients({
      type: "sync-progress",
      store: storeName,
      phase: "start",
      total: toSync.length
    })

    // Attempt sync with retries
    const response = await fetchWithRetry(syncUrl, toSync)

    if (!response) {
      await notifyClients({
        type: "sync-progress",
        store: storeName,
        phase: "error",
        total: toSync.length,
        message: "Network request failed after retries"
      })
      return
    }

    const result = await response.json()
    const syncedUuids = []
    const failedEntries = []

    for (const r of result.results) {
      if (r.status === "created" || r.status === "existing") {
        syncedUuids.push(r.client_uuid)
      } else if (r.status === "error") {
        failedEntries.push({ uuid: r.client_uuid, errors: r.errors })
      }
    }

    // Remove successfully synced entries from IndexedDB
    if (syncedUuids.length > 0) {
      const deleteDb = await openDB()
      const deleteTx = deleteDb.transaction(storeName, "readwrite")
      const deleteStore = deleteTx.objectStore(storeName)

      for (const uuid of syncedUuids) {
        deleteStore.delete(uuid)
      }

      await new Promise((resolve, reject) => {
        deleteTx.oncomplete = resolve
        deleteTx.onerror = () => reject(deleteTx.error)
      })

      deleteDb.close()
    }

    // Mark permanently failed entries
    if (failedEntries.length > 0) {
      const failDb = await openDB()
      const failTx = failDb.transaction(storeName, "readwrite")
      const failStore = failTx.objectStore(storeName)

      for (const { uuid, errors } of failedEntries) {
        const getReq = failStore.get(uuid)
        getReq.onsuccess = () => {
          const entry = getReq.result
          if (entry) {
            entry._syncFailed = true
            entry._syncErrors = errors || ["Unknown error"]
            entry._failedAt = new Date().toISOString()
            failStore.put(entry)
          }
        }
      }

      await new Promise((resolve, reject) => {
        failTx.oncomplete = resolve
        failTx.onerror = () => reject(failTx.error)
      })

      failDb.close()
    }

    // Notify clients of completion
    await notifyClients({
      type: "sync-complete",
      store: storeName,
      synced: syncedUuids.length,
      failed: failedEntries.length,
      total: toSync.length
    })
  } catch (error) {
    console.error("[Lighthouse SW] Background sync failed:", error)
    await notifyClients({
      type: "sync-progress",
      store: storeName,
      phase: "error",
      message: error.message
    })
  }
}

async function fetchWithRetry(url, entries) {
  for (let attempt = 0; attempt < MAX_SYNC_RETRIES; attempt++) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: JSON.stringify({ entries })
      })

      if (response.ok) return response

      // 4xx errors are not retryable
      if (response.status >= 400 && response.status < 500) {
        console.error(`[Lighthouse SW] Sync returned ${response.status}, not retrying`)
        return null
      }

      console.warn(`[Lighthouse SW] Sync attempt ${attempt + 1} failed: ${response.status}`)
    } catch (error) {
      console.warn(`[Lighthouse SW] Sync attempt ${attempt + 1} network error:`, error)
    }

    // Wait before retrying (unless last attempt)
    if (attempt < MAX_SYNC_RETRIES - 1) {
      await new Promise((resolve) => setTimeout(resolve, RETRY_DELAYS[attempt]))
    }
  }

  console.error("[Lighthouse SW] All sync retries exhausted")
  return null
}

async function notifyClients(message) {
  const clients = await self.clients.matchAll()
  for (const client of clients) {
    client.postMessage(message)
  }
}

function openDB() {
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

// --- Helpers ---

function isStaticAsset(pathname) {
  return /\.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?|ttf|eot)(\?.*)?$/.test(pathname) ||
         pathname.startsWith("/assets/")
}
