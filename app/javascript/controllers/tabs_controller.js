import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Show the first panel by default if none are visible
    if (this.panelTargets.length > 0 && !this.panelTargets.some(p => !p.classList.contains("hidden"))) {
      this.panelTargets[0].classList.remove("hidden")
      if (this.tabTargets.length > 0) {
        this.#activate(this.tabTargets[0])
      }
    }
  }

  select(event) {
    event.preventDefault()
    const selectedTab = event.currentTarget
    const panelId = selectedTab.dataset.tabsPanel

    // Update tab styling
    this.tabTargets.forEach(tab => this.#deactivate(tab))
    this.#activate(selectedTab)

    // Show/hide panels with animation
    this.panelTargets.forEach(panel => {
      const isTarget = panel.id === panelId
      if (isTarget) {
        panel.classList.remove("hidden")
        panel.classList.add("tab-panel-enter")
        panel.addEventListener("animationend", () => {
          panel.classList.remove("tab-panel-enter")
        }, { once: true })
      } else {
        panel.classList.add("hidden")
        panel.classList.remove("tab-panel-enter")
      }
    })
  }

  // --- Private ---

  #activate(tab) {
    tab.classList.add("border-orange-400", "text-orange-400")
    tab.classList.remove("border-transparent", "text-gray-400")
    tab.setAttribute("aria-selected", "true")
  }

  #deactivate(tab) {
    tab.classList.remove("border-orange-400", "text-orange-400")
    tab.classList.add("border-transparent", "text-gray-400")
    tab.setAttribute("aria-selected", "false")
  }
}
