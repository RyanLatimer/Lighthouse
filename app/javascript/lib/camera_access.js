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

export async function requestCameraStream(options = {}) {
  if (!cameraSupported()) {
    throw new Error("CameraUnsupported")
  }

  const constraints = buildVideoConstraints(options)

  try {
    return await navigator.mediaDevices.getUserMedia({
      video: constraints,
    })
  } catch (error) {
    if (options.deviceId || !["NotFoundError", "OverconstrainedError"].includes(error?.name)) throw error

    return navigator.mediaDevices.getUserMedia({ video: true })
  }
}

export async function listVideoInputs() {
  if (!navigator.mediaDevices?.enumerateDevices) return []

  try {
    const devices = await navigator.mediaDevices.enumerateDevices()
    return devices.filter((device) => device.kind === "videoinput")
  } catch {
    return []
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

function buildVideoConstraints(options) {
  if (options.deviceId) {
    return { deviceId: { exact: options.deviceId } }
  }

  return {
    facingMode: { ideal: options.facingMode || "environment" },
  }
}
