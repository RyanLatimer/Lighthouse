import { Controller } from "@hotwired/stimulus"
import { openDB } from "lib/lighthouse_db"

// Scoring constants matching app/models/concerns/scoring.rb
const FUEL_POINT_VALUE = 1
const AUTON_CLIMB_POINTS = 15
const CLIMB_POINTS = { None: 0, L1: 10, L2: 20, L3: 30 }

export default class extends Controller {
  static targets = [
    "autonMade", "autonMissed",
    "teleopMade", "teleopMissed",
    "endgameMade", "endgameMissed",
    "autonClimb", "endgameClimb",
    "summaryAccuracy",
    "totalPoints", "totalMade", "totalMissed",
    "dataField", "tabContent",
    "matchSelect", "teamSelect"
  ]

  static values = {
    autonMade:    { type: Number, default: 0 },
    autonMissed:  { type: Number, default: 0 },
    teleopMade:   { type: Number, default: 0 },
    teleopMissed: { type: Number, default: 0 },
    endgameMade:  { type: Number, default: 0 },
    endgameMissed:{ type: Number, default: 0 },
    autonClimb:   { type: Boolean, default: false },
    endgameClimb: { type: String, default: "None" },
    matchTeams:   { type: Object, default: {} }
  }

  connect() {
    this.updateDisplay()
    this.#initializeToggleState()
    this.#initializeTeamFilter()
    this.#cacheReferenceData()
  }

  // --- Counter actions ---

  incrementMade(event) {
    const phase = event.currentTarget.dataset.phase
    this.#incrementValue(phase, "Made")
    this.updateDisplay()
  }

  incrementMissed(event) {
    const phase = event.currentTarget.dataset.phase
    this.#incrementValue(phase, "Missed")
    this.updateDisplay()
  }

  undoMade(event) {
    const phase = event.currentTarget.dataset.phase
    this.#decrementValue(phase, "Made")
    this.updateDisplay()
  }

  undoMissed(event) {
    const phase = event.currentTarget.dataset.phase
    this.#decrementValue(phase, "Missed")
    this.updateDisplay()
  }

  // --- Climb actions ---

  toggleAutonClimb() {
    this.autonClimbValue = !this.autonClimbValue
    this.#updateToggleVisual()
    this.updateDisplay()
  }

  selectClimb(event) {
    const level = event.currentTarget.dataset.level
    this.endgameClimbValue = level

    // Highlight the selected card, deselect others
    this.element.querySelectorAll("[data-climb-card]").forEach(card => {
      const isSelected = card.dataset.level === level
      card.classList.toggle("ring-2", isSelected)
      card.classList.toggle("ring-orange-400", isSelected)
      card.classList.toggle("bg-orange-500/15", isSelected)
      card.classList.toggle("border-orange-500", isSelected)
      card.classList.toggle("shadow-lg", isSelected)
      card.classList.toggle("shadow-orange-500/10", isSelected)
      card.classList.toggle("scale-[1.02]", isSelected)
      card.classList.toggle("bg-gray-800", !isSelected)
      card.classList.toggle("border-gray-700", !isSelected)

      // Update text color
      const label = card.querySelector("p:first-child")
      if (label) {
        label.classList.toggle("text-orange-400", isSelected)
        label.classList.toggle("text-gray-300", !isSelected)
      }

      // Update ARIA
      card.setAttribute("aria-checked", isSelected)
    })

    this.updateDisplay()
  }

  // --- Tab switching ---

  switchTab(event) {
    const tab = event.currentTarget.dataset.tab

    // Update tab button styling
    this.element.querySelectorAll("[data-tab-button]").forEach(btn => {
      const isActive = btn.dataset.tab === tab
      btn.setAttribute("aria-selected", isActive)

      if (isActive) {
        btn.classList.add("bg-orange-500/15", "text-orange-400", "shadow-sm")
        btn.classList.remove("text-gray-400", "hover:text-gray-300", "hover:bg-gray-700/50")
      } else {
        btn.classList.remove("bg-orange-500/15", "text-orange-400", "shadow-sm")
        btn.classList.add("text-gray-400", "hover:text-gray-300", "hover:bg-gray-700/50")
      }
    })

    // Show/hide tab content panels with animation
    this.tabContentTargets.forEach(panel => {
      const isVisible = panel.dataset.tabPanel === tab
      if (isVisible) {
        panel.classList.remove("hidden")
        panel.classList.add("tab-panel-enter")
        // Remove animation class after it completes
        panel.addEventListener("animationend", () => {
          panel.classList.remove("tab-panel-enter")
        }, { once: true })
      } else {
        panel.classList.add("hidden")
        panel.classList.remove("tab-panel-enter")
      }
    })
  }

  // --- Match-team filtering ---

  matchChanged() {
    this.#filterTeams()
  }

  // --- Form submission ---

  submitForm(event) {
    const payload = this.#buildDataPayload()

    if (this.hasDataFieldTarget) {
      this.dataFieldTarget.value = JSON.stringify(payload)
    }

    // If offline, save to IndexedDB queue and prevent server submission
    if (!navigator.onLine) {
      event.preventDefault()
      this.#saveToOfflineQueue(payload)
    }
  }

  // --- Private helpers ---

  updateDisplay() {
    const made = this.autonMadeValue + this.teleopMadeValue + this.endgameMadeValue
    const missed = this.autonMissedValue + this.teleopMissedValue + this.endgameMissedValue
    const total = made + missed
    const accuracy = total > 0 ? ((made / total) * 100).toFixed(1) : "0.0"

    let points = made * FUEL_POINT_VALUE
    if (this.autonClimbValue) points += AUTON_CLIMB_POINTS
    points += CLIMB_POINTS[this.endgameClimbValue] || 0

    // Update phase counters
    this.#setTargetText("autonMade", this.autonMadeValue)
    this.#setTargetText("autonMissed", this.autonMissedValue)
    this.#setTargetText("teleopMade", this.teleopMadeValue)
    this.#setTargetText("teleopMissed", this.teleopMissedValue)
    this.#setTargetText("endgameMade", this.endgameMadeValue)
    this.#setTargetText("endgameMissed", this.endgameMissedValue)

    // Update totals
    this.#setTargetText("totalMade", made)
    this.#setTargetText("totalMissed", missed)
    this.#setTargetText("totalPoints", points)

    // Update accuracy display
    this.#setTargetText("summaryAccuracy", `${accuracy}%`)
  }

  #buildDataPayload() {
    // Read the auton_path from the field-map controller's hidden field
    const pathField = this.element.querySelector("[data-auton-path-field]")
    let autonPath = []
    try {
      autonPath = pathField ? JSON.parse(pathField.value) : []
    } catch { /* empty */ }

    return {
      auton_fuel_made: this.autonMadeValue,
      auton_fuel_missed: this.autonMissedValue,
      teleop_fuel_made: this.teleopMadeValue,
      teleop_fuel_missed: this.teleopMissedValue,
      endgame_fuel_made: this.endgameMadeValue,
      endgame_fuel_missed: this.endgameMissedValue,
      auton_climb: this.autonClimbValue,
      endgame_climb: this.endgameClimbValue,
      auton_path: autonPath
    }
  }

  async #saveToOfflineQueue(payload) {
    try {
      const db = await openDB()
      const form = this.element.closest("form")

      const entry = {
        client_uuid: crypto.randomUUID(),
        match_id: form?.querySelector("[name*='match_id']")?.value || null,
        frc_team_id: form?.querySelector("[name*='frc_team_id']")?.value || null,
        event_id: form?.querySelector("[name*='event_id']")?.value || null,
        notes: form?.querySelector("[name*='notes']")?.value || "",
        data: payload,
        created_at: new Date().toISOString()
      }

      const tx = db.transaction("offline_entries", "readwrite")
      tx.objectStore("offline_entries").add(entry)
      await new Promise((resolve, reject) => {
        tx.oncomplete = resolve
        tx.onerror = () => reject(tx.error)
      })

      db.close()

      // Notify the user and update the connectivity banner
      this.#showOfflineConfirmation()
      window.dispatchEvent(new CustomEvent("lighthouse:entry-queued"))
    } catch (error) {
      console.error("[Lighthouse] Failed to save offline entry:", error)
      alert("Failed to save entry offline. Please try again.")
    }
  }

  async #cacheReferenceData() {
    // Cache match/team dropdown data in IndexedDB for offline form hydration
    if (!navigator.onLine) return
    try {
      const form = this.element.closest("form")
      const eventId = form?.querySelector("[name*='event_id']")?.value
      if (!eventId) return

      // Collect team options from the current dropdown
      const teams = this._allTeamOptions?.filter(o => o.value !== "").map(o => ({
        value: o.value,
        text: o.text
      })) || []

      // matchTeams is already a Stimulus value
      const matchTeams = this.matchTeamsValue || {}

      // Collect match options from the match dropdown
      const matches = this.hasMatchSelectTarget
        ? Array.from(this.matchSelectTarget.options).filter(o => o.value !== "").map(o => ({
            value: o.value,
            text: o.text
          }))
        : []

      const db = await openDB()
      const tx = db.transaction("event_data", "readwrite")
      tx.objectStore("event_data").put({
        event_id: eventId,
        teams,
        matches,
        match_teams: matchTeams,
        cached_at: new Date().toISOString()
      })
      await new Promise((resolve, reject) => {
        tx.oncomplete = resolve
        tx.onerror = () => reject(tx.error)
      })
      db.close()
    } catch (error) {
      console.warn("[Lighthouse] Failed to cache reference data:", error)
    }
  }

  #showOfflineConfirmation() {
    const banner = document.createElement("div")
    banner.className = "fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-amber-600 text-white px-6 py-3 rounded-lg shadow-lg font-medium animate-slide-down"
    banner.innerHTML = `
      <div class="flex items-center gap-2">
        <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span>Entry saved offline. It will sync when you reconnect.</span>
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

  #incrementValue(phase, suffix) {
    const key = `${phase}${suffix}Value`
    this[key] = this[key] + 1
  }

  #decrementValue(phase, suffix) {
    const key = `${phase}${suffix}Value`
    this[key] = Math.max(0, this[key] - 1)
  }

  #setTargetText(name, value) {
    const capitalizedName = name.charAt(0).toUpperCase() + name.slice(1)
    if (this[`has${capitalizedName}Target`]) {
      const target = this[`${name}Target`]
      target.textContent = value
    }
  }

  #initializeToggleState() {
    if (this.autonClimbValue) {
      this.#updateToggleVisual()
    }
  }

  #updateToggleVisual() {
    if (!this.hasAutonClimbTarget) return

    const target = this.autonClimbTarget
    const track = target.querySelector("[data-toggle-track]")
    const knob = target.querySelector("[data-toggle-knob]")

    // Update ARIA
    target.setAttribute("aria-checked", this.autonClimbValue)

    if (this.autonClimbValue) {
      target.classList.add("ring-2", "ring-orange-400", "bg-orange-900/50")
      if (track) track.classList.replace("bg-gray-700", "bg-orange-500")
      if (knob) {
        knob.style.left = "auto"
        knob.style.right = "4px"
      }
    } else {
      target.classList.remove("ring-2", "ring-orange-400", "bg-orange-900/50")
      if (track) track.classList.replace("bg-orange-500", "bg-gray-700")
      if (knob) {
        knob.style.left = "4px"
        knob.style.right = "auto"
      }
    }
  }

  #initializeTeamFilter() {
    if (!this.hasMatchSelectTarget || !this.hasTeamSelectTarget) return

    // Cache all original team options so we can restore them
    this._allTeamOptions = Array.from(this.teamSelectTarget.options).map(opt => ({
      value: opt.value,
      text: opt.text
    }))

    // If a match is already selected (e.g. editing an entry), filter now
    if (this.matchSelectTarget.value) {
      this.#filterTeams()
    }
  }

  #filterTeams() {
    if (!this.hasMatchSelectTarget || !this.hasTeamSelectTarget) return

    const select = this.teamSelectTarget
    const matchId = this.matchSelectTarget.value
    const currentTeamId = select.value

    // Clear existing options
    select.innerHTML = ""

    // Always add the prompt option
    const prompt = document.createElement("option")
    prompt.value = ""
    prompt.textContent = "Select team..."
    select.appendChild(prompt)

    if (!matchId) {
      // No match selected: restore all teams
      this._allTeamOptions.forEach(opt => {
        if (opt.value === "") return // skip original prompt
        const option = document.createElement("option")
        option.value = opt.value
        option.textContent = opt.text
        select.appendChild(option)
      })
    } else {
      // Match selected: show only teams in this match, grouped by alliance
      const teams = this.matchTeamsValue[matchId] || []

      const redTeams = teams.filter(t => t.color === "red")
      const blueTeams = teams.filter(t => t.color === "blue")

      if (redTeams.length > 0) {
        const redGroup = document.createElement("optgroup")
        redGroup.label = "Red Alliance"
        redTeams.forEach(t => {
          const option = document.createElement("option")
          option.value = t.id
          option.textContent = `${t.number} - ${t.name}`
          redGroup.appendChild(option)
        })
        select.appendChild(redGroup)
      }

      if (blueTeams.length > 0) {
        const blueGroup = document.createElement("optgroup")
        blueGroup.label = "Blue Alliance"
        blueTeams.forEach(t => {
          const option = document.createElement("option")
          option.value = t.id
          option.textContent = `${t.number} - ${t.name}`
          blueGroup.appendChild(option)
        })
        select.appendChild(blueGroup)
      }
    }

    // Restore previous selection if it's still a valid option
    const validValues = new Set(Array.from(select.options).map(o => o.value))
    if (validValues.has(currentTeamId)) {
      select.value = currentTeamId
    } else {
      select.value = ""
    }
  }
}
