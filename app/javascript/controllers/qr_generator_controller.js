import { Controller } from "@hotwired/stimulus"
import QRCode from "qrcode"
import { encode } from "lib/qr_payload"

/**
 * QR Generator Controller
 *
 * Renders a QR code containing a compact encoding of a scouting entry's data.
 * Attached to a container element on the scouting entry show page.
 *
 * Usage:
 *   <div data-controller="qr-generator"
 *        data-qr-generator-entry-value='<%= entry_json %>'>
 *     <canvas data-qr-generator-target="canvas"></canvas>
 *   </div>
 *
 * Values:
 *   entry (Object): The full scouting entry data to encode
 */
export default class extends Controller {
  static targets = ["canvas", "error", "size"]
  static values = {
    entry: Object,
  }

  connect() {
    this.generateQR()
  }

  async generateQR() {
    try {
      const payload = encode(this.entryValue)
      const byteSize = new Blob([payload]).size

      // Show payload size for debugging/awareness
      if (this.hasSizeTarget) {
        this.sizeTarget.textContent = `${byteSize} bytes`
      }

      await QRCode.toCanvas(this.canvasTarget, payload, {
        width: 280,
        margin: 2,
        color: {
          dark: "#FFFFFF",
          light: "#00000000", // transparent background
        },
        errorCorrectionLevel: byteSize > 2000 ? "L" : "M",
      })
    } catch (err) {
      console.error("QR generation failed:", err)
      if (this.hasErrorTarget) {
        this.errorTarget.textContent = "QR code too large to generate. Data may need to be simplified."
        this.errorTarget.classList.remove("hidden")
      }
    }
  }
}
