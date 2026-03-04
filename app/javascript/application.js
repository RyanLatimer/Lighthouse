// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "chartkick"
import "Chart.bundle"

// --- Service Worker Registration ---

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js").then((registration) => {
    // Send the current CSRF token to the service worker for sync requests
    const sendCsrfToken = (sw) => {
      const token = document.querySelector("meta[name='csrf-token']")?.content
      if (token && sw) {
        sw.postMessage({ type: "csrf-token", token })
      }
    }

    // Send to active SW immediately
    if (registration.active) {
      sendCsrfToken(registration.active)
    }

    // Send when a new SW takes over
    registration.addEventListener("updatefound", () => {
      const newWorker = registration.installing
      if (newWorker) {
        newWorker.addEventListener("statechange", () => {
          if (newWorker.state === "activated") {
            sendCsrfToken(newWorker)
          }
        })
      }
    })

    // Also send on controllerchange (when a waiting SW is promoted)
    navigator.serviceWorker.addEventListener("controllerchange", () => {
      sendCsrfToken(navigator.serviceWorker.controller)
    })

    // Resend CSRF token on each Turbo page visit (Rails may rotate the token)
    document.addEventListener("turbo:load", () => {
      sendCsrfToken(navigator.serviceWorker.controller)
    })
  }).catch((error) => {
    console.warn("[Lighthouse] Service worker registration failed:", error)
  })
}
