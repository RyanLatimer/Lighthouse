import { Controller } from "@hotwired/stimulus"

/**
 * Manages multiple auton path entries for pit scouting.
 * Each path has its own field-map canvas, fuel scored count, and action checkboxes.
 * All path data is serialized into a single hidden JSON field on form submit.
 *
 * Data structure per path:
 *   { strokes: [[{x,y},...]], fuel_scored: 3, actions: ["bump", "climb"] }
 */
export default class extends Controller {
  static targets = ["container", "hiddenField"]
  static values = {
    paths: { type: Array, default: [] },
    fieldImage: { type: String, default: "" }
  }

  connect() {
    this.pathCounter = 0

    // Restore existing paths from value (edit mode)
    if (this.pathsValue.length > 0) {
      this.pathsValue.forEach(pathData => this.#addPathBlock(pathData))
    }
  }

  addPath() {
    this.#addPathBlock(null)
  }

  removePath(event) {
    const block = event.currentTarget.closest("[data-auton-path-block]")
    if (block) {
      block.remove()
      this.#renumberBlocks()
      this.#syncHiddenField()
    }
  }

  // Called externally (e.g. from form submit) to ensure data is serialized
  serialize() {
    this.#syncHiddenField()
  }

  // --- Private ---

  #addPathBlock(existingData) {
    this.pathCounter++
    const index = this.pathCounter

    const block = document.createElement("div")
    block.setAttribute("data-auton-path-block", index)
    block.className = "bg-gray-800 rounded-lg p-3 space-y-3"

    const strokesJson = existingData?.strokes ? JSON.stringify(existingData.strokes) : "[]"
    const fuelScored = existingData?.fuel_scored || 0
    const actions = existingData?.actions || []

    // The field-map controller scope wraps the canvas, undo/clear buttons, AND the hidden field
    block.innerHTML = `
      <div class="flex items-center justify-between mb-1">
        <span class="text-xs text-gray-400 font-medium" data-path-label>Auto Path #${index}</span>
        <button type="button"
                class="text-xs text-red-400 hover:text-red-300 transition"
                data-action="click->auton-paths#removePath">
          Remove
        </button>
      </div>

      <div data-controller="field-map"
           data-field-map-strokes-value='${this.#escapeAttr(strokesJson)}'>
        <div class="relative rounded-lg overflow-hidden border border-gray-700 bg-gray-800 touch-none">
          <img src="${this.#escapeAttr(this.fieldImageValue)}"
               class="w-full block select-none pointer-events-none"
               alt="Field map"
               data-field-map-target="image" />
          <canvas class="absolute inset-0 w-full h-full cursor-crosshair"
                  data-field-map-target="canvas"
                  data-action="pointerdown->field-map#startStroke pointermove->field-map#continueStroke pointerup->field-map#endStroke pointerleave->field-map#endStroke"></canvas>
        </div>

        <div class="flex gap-2 mt-2">
          <button type="button"
                  class="px-3 py-1.5 text-xs font-medium rounded-lg bg-gray-700 hover:bg-gray-600 text-gray-400 hover:text-gray-300 transition select-none"
                  data-action="click->field-map#undo">
            Undo
          </button>
          <button type="button"
                  class="px-3 py-1.5 text-xs font-medium rounded-lg bg-gray-700 hover:bg-gray-600 text-gray-400 hover:text-gray-300 transition select-none"
                  data-action="click->field-map#clear">
            Clear
          </button>
        </div>

        <input type="hidden" data-field-map-target="hiddenField" data-path-strokes value='${this.#escapeAttr(strokesJson)}' />
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="block text-xs text-gray-400 mb-1">Fuel Scored</label>
          <input type="number" min="0" value="${fuelScored}" data-path-fuel
                 class="w-full bg-gray-700 border border-gray-600 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent transition" />
        </div>
      </div>

      <div>
        <label class="block text-xs text-gray-400 mb-1.5">Actions</label>
        <div class="flex flex-wrap gap-2">
          ${["Bump", "Trench", "Outpost", "Depot", "Climb"].map(action => {
            const checked = actions.includes(action) ? "checked" : ""
            return `
              <label class="flex items-center gap-2 px-3 py-1.5 rounded-lg border cursor-pointer transition text-sm font-medium
                bg-gray-700 border-gray-600 text-gray-400 hover:border-gray-500
                has-[:checked]:bg-amber-500/20 has-[:checked]:border-amber-500/30 has-[:checked]:text-amber-400">
                <input type="checkbox" value="${action}" data-path-action class="hidden" ${checked} />
                ${action}
              </label>`
          }).join("")}
        </div>
      </div>
    `

    this.containerTarget.appendChild(block)
  }

  #renumberBlocks() {
    const blocks = this.containerTarget.querySelectorAll("[data-auton-path-block]")
    blocks.forEach((block, i) => {
      const label = block.querySelector("[data-path-label]")
      if (label) label.textContent = `Auto Path #${i + 1}`
      block.setAttribute("data-auton-path-block", i + 1)
    })
    this.pathCounter = blocks.length
  }

  #syncHiddenField() {
    if (!this.hasHiddenFieldTarget) return

    const blocks = this.containerTarget.querySelectorAll("[data-auton-path-block]")
    const paths = []

    blocks.forEach(block => {
      const strokesField = block.querySelector("[data-path-strokes]")
      let strokes = []
      try {
        strokes = strokesField ? JSON.parse(strokesField.value) : []
      } catch { /* empty */ }

      const fuelField = block.querySelector("[data-path-fuel]")
      const fuelScored = fuelField ? parseInt(fuelField.value, 10) || 0 : 0

      const actionCheckboxes = block.querySelectorAll("[data-path-action]:checked")
      const actions = Array.from(actionCheckboxes).map(cb => cb.value)

      paths.push({ strokes, fuel_scored: fuelScored, actions })
    })

    this.hiddenFieldTarget.value = JSON.stringify(paths)
  }

  #escapeAttr(str) {
    return str.replace(/&/g, "&amp;").replace(/'/g, "&#39;").replace(/"/g, "&quot;")
  }
}
