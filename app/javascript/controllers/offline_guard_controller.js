import { Controller } from "@hotwired/stimulus"

/**
 * Prevents form submissions and destructive actions when the user is offline.
 * Used on non-scouting forms that require server connectivity.
 *
 * Usage on forms:
 *   <form data-controller="offline-guard" data-action="submit->offline-guard#check">
 *
 * Usage on button_to (wraps in a form):
 *   Add via the form: option on button_to, or wrap with a parent div.
 */
export default class extends Controller {
  check(event) {
    if (!navigator.onLine) {
      event.preventDefault()
      event.stopImmediatePropagation()
      this.#showOfflineWarning()
    }
  }

  #showOfflineWarning() {
    const banner = document.createElement("div")
    banner.className = "fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-red-600 text-white px-6 py-3 rounded-lg shadow-lg font-medium max-w-sm text-center"
    banner.innerHTML = `
      <div class="flex items-center gap-2">
        <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636a9 9 0 010 12.728M5.636 5.636a9 9 0 000 12.728M12 12v.01" />
        </svg>
        <span>This action requires an internet connection.</span>
      </div>
    `
    document.body.appendChild(banner)

    setTimeout(() => {
      banner.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
      banner.style.opacity = "0"
      banner.style.transform = "translate(-50%, -8px)"
      setTimeout(() => banner.remove(), 300)
    }, 3000)
  }
}
