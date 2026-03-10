export function cameraSupported() {
  return Boolean(navigator.mediaDevices?.getUserMedia)
}

export async function getCameraPermissionState() {
  if (!navigator.permissions?.query) return "unknown"

  try {
    const result = await navigator.permissions.query({ name: "camera" })
    return result.state || "unknown"
  } catch {
    return "unknown"
  }
}

export async function requestCameraStream() {
  if (!cameraSupported()) {
    throw new Error("CameraUnsupported")
  }

  try {
    return await navigator.mediaDevices.getUserMedia({
      video: { facingMode: { ideal: "environment" } },
    })
  } catch (error) {
    if (!["NotFoundError", "OverconstrainedError"].includes(error?.name)) throw error

    return navigator.mediaDevices.getUserMedia({ video: true })
  }
}

export function stopCameraStream(stream) {
  stream?.getTracks().forEach((track) => track.stop())
}

export function cameraErrorMessage(error, permissionState = "unknown") {
  if (error?.message === "CameraUnsupported") {
    return "Camera access is not supported on this device or browser."
  }

  switch (error?.name) {
    case "NotAllowedError":
    case "SecurityError":
      return permissionState === "denied" ?
        "Camera access is blocked. Allow camera permissions in your browser settings and try again." :
        "Camera access was denied. Allow camera permissions and try again."
    case "NotFoundError":
    case "OverconstrainedError":
      return "No camera was found. Try another device or browser."
    case "NotReadableError":
    case "AbortError":
      return "Camera is unavailable right now. Close other apps using it and try again."
    default:
      return "Unable to access the camera right now. Please try again."
  }
}
