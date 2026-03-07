import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "status", "testButton"]
  static values = {
    vapidKey: String
  }

  async connect() {
    const diagnostics = this.browserDiagnostics()
    this.supported = diagnostics.supported
    this.subscribed = false
    this.registration = null
    this.subscription = null

    if (!this.supported) {
      this.setUnavailable(diagnostics.message)
      console.warn("[Lighthouse] Push unsupported diagnostics:", diagnostics)
      return
    }

    if (!this.vapidKeyValue) {
      this.setUnavailable("Push notifications are not configured on the server (missing VAPID public key).")
      return
    }

    try {
      this.registration = await navigator.serviceWorker.ready
      this.subscription = await this.registration.pushManager.getSubscription()
      this.subscribed = Boolean(this.subscription)
      this.renderState()
    } catch (error) {
      console.warn("[Lighthouse] Unable to initialize push controller:", error)
      this.setUnavailable("Unable to initialize notifications.")
    }
  }

  async toggle() {
    if (!this.supported || !this.registration) return

    this.setActionButtonsDisabled(true)

    try {
      if (this.subscribed && this.subscription) {
        const endpoint = this.subscription.endpoint
        await this.subscription.unsubscribe()
        await this.unsubscribeOnServer(endpoint)
        this.subscription = null
        this.subscribed = false
      } else {
        const permission = await Notification.requestPermission()
        if (permission !== "granted") {
          this.statusTarget.textContent = "Notifications are blocked. Enable them in browser settings."
          return
        }

        this.subscription = await this.registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.urlBase64ToUint8Array(this.vapidKeyValue)
        })

        await this.subscribeOnServer(this.subscription)
        this.subscribed = true
      }

      this.renderState()
    } catch (error) {
      console.warn("[Lighthouse] Failed to toggle push subscription:", error)
      this.statusTarget.textContent = "Failed to update notifications. Please try again."
    } finally {
      this.setActionButtonsDisabled(false)
    }
  }

  async sendTestNotification() {
    if (!this.supported || !this.subscribed) return

    this.setActionButtonsDisabled(true)

    try {
      const response = await fetch("/web_push_subscriptions/test_notification", {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        }
      })

      if (!response.ok) {
        throw new Error(`Test notification failed with status ${response.status}`)
      }

      this.statusTarget.textContent = "Test notification sent. Check your device notification center."
    } catch (error) {
      console.warn("[Lighthouse] Failed to send test notification:", error)
      this.statusTarget.textContent = "Unable to send test notification. Please verify subscription and try again."
    } finally {
      this.setActionButtonsDisabled(false)
    }
  }

  renderState() {
    if (!this.hasButtonTarget || !this.hasStatusTarget) return

    if (this.subscribed) {
      this.buttonTarget.textContent = "Disable Push Notifications"
      this.buttonTarget.classList.remove("btn-primary")
      this.buttonTarget.classList.add("btn-secondary")
      this.statusTarget.textContent = "Enabled. You\u2019ll be notified when your scouting shifts are approaching."
      if (this.hasTestButtonTarget) {
        this.testButtonTarget.disabled = false
      }
    } else {
      this.buttonTarget.textContent = "Enable Push Notifications"
      this.buttonTarget.classList.remove("btn-secondary")
      this.buttonTarget.classList.add("btn-primary")
      this.statusTarget.textContent = "Disabled. Enable to get push reminders before your scouting shifts."
      if (this.hasTestButtonTarget) {
        this.testButtonTarget.disabled = true
      }
    }
  }

  setUnavailable(message) {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.textContent = "Notifications Unavailable"
      this.buttonTarget.classList.remove("btn-primary")
      this.buttonTarget.classList.add("btn-secondary")
    }
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
    if (this.hasTestButtonTarget) {
      this.testButtonTarget.disabled = true
    }
  }

  setActionButtonsDisabled(disabled) {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = disabled
    }
    if (this.hasTestButtonTarget) {
      this.testButtonTarget.disabled = disabled || !this.subscribed
    }
  }

  browserDiagnostics() {
    const issues = []

    if (!window.isSecureContext) {
      issues.push("site is not running in a secure context (HTTPS or localhost)")
    }

    if (!("serviceWorker" in navigator)) {
      issues.push("service workers are unavailable")
    }

    if (!("PushManager" in window)) {
      issues.push("Push API is unavailable")
    }

    if (!("Notification" in window)) {
      issues.push("Notification API is unavailable")
    }

    const inStandalone = window.matchMedia && window.matchMedia("(display-mode: standalone)").matches

    if (issues.length === 0) {
      return {
        supported: true,
        message: "",
        secureContext: window.isSecureContext,
        hasServiceWorker: "serviceWorker" in navigator,
        hasPushManager: "PushManager" in window,
        hasNotification: "Notification" in window,
        displayModeStandalone: inStandalone,
        notificationPermission: Notification.permission
      }
    }

    return {
      supported: false,
      message: `Push is unavailable: ${issues.join("; ")}.`
    }
  }

  async subscribeOnServer(subscription) {
    const response = await fetch("/web_push_subscriptions", {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ subscription: subscription.toJSON() })
      })

    if (!response.ok) {
      throw new Error(`Subscribe failed with status ${response.status}`)
    }
  }

  async unsubscribeOnServer(endpoint) {
    const response = await fetch("/web_push_subscriptions/unsubscribe", {
        method: "DELETE",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({ endpoint })
      })

    if (!response.ok) {
      throw new Error(`Unsubscribe failed with status ${response.status}`)
    }
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; i++) {
      outputArray[i] = rawData.charCodeAt(i)
    }

    return outputArray
  }
}
