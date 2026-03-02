import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "list", "rank"]

  connect() {
    this.draggedItem = null
    this.placeholder = null
    this.#enableDragging()
    this.#enablePointerDragging()
  }

  // --- HTML5 Drag Events (Desktop) ---

  dragstart(event) {
    this.draggedItem = event.currentTarget
    event.currentTarget.classList.add("opacity-50", "scale-[0.98]")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", event.currentTarget.dataset.sortableId)
    this.#createPlaceholder()
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.target.closest("[data-sortable-target='item']")
    if (!target || target === this.draggedItem || target === this.placeholder) return

    this.#positionPlaceholder(target, event.clientY)
  }

  drop(event) {
    event.preventDefault()
    this.#finalizeDrop()
  }

  dragend(event) {
    event.currentTarget.classList.remove("opacity-50", "scale-[0.98]")
    this.#removePlaceholder()
    this.draggedItem = null
  }

  // --- Pointer Events (Touch + Mouse fallback) ---

  #enablePointerDragging() {
    this.itemTargets.forEach(item => {
      const handle = item.querySelector("[data-sortable-handle]") || item
      handle.addEventListener("pointerdown", (e) => this.#onPointerDown(e, item))
    })
  }

  #onPointerDown(event, item) {
    // Only handle touch events (let HTML5 drag handle mouse)
    if (event.pointerType === "mouse") return

    event.preventDefault()
    this.draggedItem = item
    this.touchStartY = event.clientY
    this.itemHeight = item.offsetHeight

    // Visual feedback
    item.classList.add("opacity-50", "scale-[0.98]", "z-10", "relative")
    this.#createPlaceholder()

    const onPointerMove = (e) => {
      e.preventDefault()
      const target = document.elementFromPoint(e.clientX, e.clientY)?.closest("[data-sortable-target='item']")
      if (target && target !== this.draggedItem && target !== this.placeholder) {
        this.#positionPlaceholder(target, e.clientY)
      }
    }

    const onPointerUp = () => {
      document.removeEventListener("pointermove", onPointerMove)
      document.removeEventListener("pointerup", onPointerUp)
      item.classList.remove("opacity-50", "scale-[0.98]", "z-10", "relative")
      this.#finalizeDrop()
      this.draggedItem = null
    }

    document.addEventListener("pointermove", onPointerMove, { passive: false })
    document.addEventListener("pointerup", onPointerUp, { once: true })
  }

  // --- Shared Helpers ---

  #createPlaceholder() {
    if (this.placeholder) return
    this.placeholder = document.createElement("div")
    this.placeholder.className = "h-1 bg-orange-500 rounded-full mx-4 my-1 transition-all duration-150 shadow-sm shadow-orange-500/30"
    this.placeholder.dataset.placeholder = "true"
  }

  #positionPlaceholder(target, clientY) {
    if (!this.placeholder || !this.draggedItem) return

    const rect = target.getBoundingClientRect()
    const midY = rect.top + rect.height / 2
    const list = this.hasListTarget ? this.listTarget : this.element

    if (clientY < midY) {
      list.insertBefore(this.placeholder, target)
    } else {
      target.after(this.placeholder)
    }
  }

  #removePlaceholder() {
    if (this.placeholder && this.placeholder.parentNode) {
      this.placeholder.parentNode.removeChild(this.placeholder)
    }
    this.placeholder = null
  }

  #finalizeDrop() {
    if (this.placeholder && this.placeholder.parentNode && this.draggedItem) {
      this.placeholder.parentNode.insertBefore(this.draggedItem, this.placeholder)
    }
    this.#removePlaceholder()
    this.#updateRankNumbers()
    this.#saveOrder()
  }

  #enableDragging() {
    this.itemTargets.forEach(item => {
      item.setAttribute("draggable", "true")
    })
  }

  #updateRankNumbers() {
    const list = this.hasListTarget ? this.listTarget : this.element
    const items = [...list.querySelectorAll("[data-sortable-target='item']")]
    items.forEach((item, index) => {
      const rankEl = item.querySelector("[data-sortable-target='rank']")
      if (rankEl) {
        rankEl.textContent = index + 1
        // Brief highlight animation
        rankEl.classList.add("animate-bounce-number")
        rankEl.addEventListener("animationend", () => {
          rankEl.classList.remove("animate-bounce-number")
        }, { once: true })
      }
    })
  }

  async #saveOrder() {
    const list = this.hasListTarget ? this.listTarget : this.element
    const items = [...list.querySelectorAll("[data-sortable-target='item']")]
    const orderedIds = items.map(item => item.dataset.sortableId)

    // Update hidden field if present
    const hiddenField = this.element.querySelector("[data-sortable-order]")
    if (hiddenField) {
      hiddenField.value = JSON.stringify(orderedIds)
    }

    // Auto-save via PATCH if a save URL is configured
    const url = this.element.dataset.sortableSaveUrl
    if (!url) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken || "",
          "Accept": "application/json"
        },
        body: JSON.stringify({ entries: orderedIds })
      })

      if (response.ok) {
        this.#showToast("Order saved", "success")
      } else {
        this.#showToast("Failed to save order", "error")
      }
    } catch (error) {
      console.error("[ScoutRail] Failed to save sort order:", error)
      this.#showToast("Failed to save order", "error")
    }
  }

  #showToast(message, type = "success") {
    const toast = document.createElement("div")
    const isSuccess = type === "success"
    toast.className = `fixed bottom-24 md:bottom-8 left-1/2 -translate-x-1/2 z-50 px-4 py-2 rounded-lg shadow-lg text-sm font-medium animate-slide-down flex items-center gap-2 ${
      isSuccess
        ? "bg-orange-600 text-white"
        : "bg-red-600 text-white"
    }`

    const icon = isSuccess
      ? '<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>'
      : '<svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>'

    toast.innerHTML = `${icon}<span>${message}</span>`
    document.body.appendChild(toast)

    setTimeout(() => {
      toast.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
      toast.style.opacity = "0"
      toast.style.transform = "translate(-50%, 8px)"
      setTimeout(() => toast.remove(), 300)
    }, 2000)
  }
}
