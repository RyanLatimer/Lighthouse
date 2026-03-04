import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Slide in from the left
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(-1rem)"
    this.element.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"

    requestAnimationFrame(() => {
      this.element.style.opacity = "1"
      this.element.style.transform = "translateX(0)"
    })

    this.timeout = setTimeout(() => this.dismiss(), 4000)

    this.element.addEventListener("mouseenter", this.#pause)
    this.element.addEventListener("mouseleave", this.#resume)
    this.element.addEventListener("focusin", this.#pause)
    this.element.addEventListener("focusout", this.#resume)
  }

  disconnect() {
    clearTimeout(this.timeout)
    this.element.removeEventListener("mouseenter", this.#pause)
    this.element.removeEventListener("mouseleave", this.#resume)
    this.element.removeEventListener("focusin", this.#pause)
    this.element.removeEventListener("focusout", this.#resume)
  }

  dismiss() {
    clearTimeout(this.timeout)

    this.element.style.transition = "opacity 0.2s ease-out, transform 0.2s ease-out"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(-1rem)"

    setTimeout(() => this.element.remove(), 200)
  }

  #pause = () => {
    clearTimeout(this.timeout)
  }

  #resume = () => {
    this.timeout = setTimeout(() => this.dismiss(), 2000)
  }
}
