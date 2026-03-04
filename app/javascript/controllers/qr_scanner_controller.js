import { Controller } from "@hotwired/stimulus"
import jsQR from "jsqr"
import { decode } from "lib/qr_payload"

/**
 * QR Scanner Controller
 *
 * Uses the device camera to scan QR codes containing scouting entry data.
 * Decodes the compact payload and submits it to the server for import.
 *
 * Targets:
 *   video   - Hidden <video> element for camera stream
 *   canvas  - Hidden <canvas> for frame extraction
 *   preview - Visible preview area showing the camera feed
 *   status  - Text element showing scan status
 *   result  - Container for showing import results
 *   list    - Container for appending imported entry results
 */
export default class extends Controller {
  static targets = ["video", "canvas", "preview", "status", "result", "list", "startBtn"]
  static values = {
    importUrl: String,   // POST endpoint for QR import
    scanning: { type: Boolean, default: false },
  }

  connect() {
    this.animationId = null
    this.stream = null
  }

  disconnect() {
    this.stopScanning()
  }

  async start() {
    if (this.scanningValue) return

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: "environment" },
      })

      this.videoTarget.srcObject = this.stream
      this.videoTarget.setAttribute("playsinline", true)
      await this.videoTarget.play()

      this.scanningValue = true
      this.statusTarget.textContent = "Point camera at a QR code..."
      this.statusTarget.className = "text-sm text-gray-400 mt-3"

      if (this.hasStartBtnTarget) {
        this.startBtnTarget.classList.add("hidden")
      }
      this.previewTarget.classList.remove("hidden")

      this.tick()
    } catch (err) {
      console.error("Camera access failed:", err)
      this.statusTarget.textContent = "Camera access denied. Please allow camera permissions and try again."
      this.statusTarget.className = "text-sm text-red-400 mt-3"
    }
  }

  stop() {
    this.stopScanning()
    if (this.hasStartBtnTarget) {
      this.startBtnTarget.classList.remove("hidden")
    }
    this.previewTarget.classList.add("hidden")
    this.statusTarget.textContent = "Scanner stopped."
    this.statusTarget.className = "text-sm text-gray-500 mt-3"
  }

  stopScanning() {
    this.scanningValue = false

    if (this.animationId) {
      cancelAnimationFrame(this.animationId)
      this.animationId = null
    }

    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
      this.stream = null
    }
  }

  tick() {
    if (!this.scanningValue) return

    const video = this.videoTarget
    if (video.readyState !== video.HAVE_ENOUGH_DATA) {
      this.animationId = requestAnimationFrame(() => this.tick())
      return
    }

    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d", { willReadFrequently: true })
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height)

    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
    const code = jsQR(imageData.data, imageData.width, imageData.height, {
      inversionAttempts: "dontInvert",
    })

    if (code && code.data) {
      this.handleScan(code.data)
    } else {
      this.animationId = requestAnimationFrame(() => this.tick())
    }
  }

  async handleScan(rawData) {
    // Pause scanning while processing
    this.scanningValue = false

    this.statusTarget.textContent = "QR code detected! Importing..."
    this.statusTarget.className = "text-sm text-orange-400 mt-3"

    try {
      const entry = decode(rawData)
      await this.submitEntry(entry)
    } catch (err) {
      console.error("QR decode/import failed:", err)
      this.appendResult("error", "Invalid QR code — not a Lighthouse scouting entry.", null)
    }

    // Resume scanning after a short delay
    setTimeout(() => {
      if (this.stream) {
        this.scanningValue = true
        this.statusTarget.textContent = "Scanning for next QR code..."
        this.statusTarget.className = "text-sm text-gray-400 mt-3"
        this.tick()
      }
    }, 2000)
  }

  async submitEntry(entry) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(this.importUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
        },
        credentials: "same-origin",
        body: JSON.stringify({ entry }),
      })

      if (!response.ok) {
        const text = await response.text()
        throw new Error(`Server error: ${response.status} ${text}`)
      }

      const result = await response.json()

      if (result.status === "created") {
        this.appendResult("created", `Team ${result.team_number} — ${result.match_name}`, result.id)
      } else if (result.status === "existing") {
        this.appendResult("existing", `Team ${result.team_number} — ${result.match_name} (already exists)`, result.id)
      } else if (result.status === "updated") {
        this.appendResult("updated", `Team ${result.team_number} — ${result.match_name} (updated — newer data)`, result.id)
      } else if (result.status === "skipped") {
        this.appendResult("skipped", `Team ${result.team_number} — ${result.match_name} (server copy is newer)`, result.id)
      } else {
        this.appendResult("error", `Import failed: ${(result.errors || []).join(", ")}`, null)
      }
    } catch (err) {
      console.error("Import request failed:", err)
      this.appendResult("error", `Network error: ${err.message}`, null)
    }
  }

  appendResult(status, message, entryId) {
    if (this.hasResultTarget) {
      this.resultTarget.classList.remove("hidden")
    }

    const colors = {
      created:  "text-emerald-400 border-emerald-500/30",
      updated:  "text-blue-400 border-blue-500/30",
      existing: "text-amber-400 border-amber-500/30",
      skipped:  "text-gray-400 border-gray-500/30",
      error:    "text-red-400 border-red-500/30",
    }

    const icons = {
      created:  "&#10003;",  // checkmark
      updated:  "&#8635;",   // refresh
      existing: "&#8212;",   // dash
      skipped:  "&#8594;",   // arrow
      error:    "&#10007;",  // X
    }

    const div = document.createElement("div")
    div.className = `flex items-center gap-2 p-3 rounded-lg border bg-gray-900/50 ${colors[status] || colors.error}`
    div.innerHTML = `
      <span class="text-lg font-bold">${icons[status] || "?"}</span>
      <span class="text-sm flex-1">${message}</span>
      ${entryId ? `<a href="/scouting_entries/${entryId}" class="text-xs text-orange-400 hover:text-orange-300 underline">View</a>` : ""}
    `

    if (this.hasListTarget) {
      this.listTarget.prepend(div)
    }
  }
}
