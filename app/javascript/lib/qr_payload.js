/**
 * QR Payload encoder/decoder for Lighthouse scouting entries.
 *
 * Encodes a scouting entry into a compact JSON string suitable for QR codes
 * (~3 KB limit). Uses short keys and compact coordinate encoding to minimize
 * payload size.
 *
 * Format version 1 (v:1):
 *   - Short single/two-character keys for all fields
 *   - auton_path coordinates quantized to integers (x*1000, y*1000)
 *   - Strokes stored as flat arrays: [[x,y,x,y,...], ...]
 *   - Points downsampled if total exceeds MAX_PATH_POINTS
 */

// Maximum number of path points across all strokes before downsampling
const MAX_PATH_POINTS = 150

// Short key mapping: compact key -> full key
const KEY_MAP = {
  v:   "_version",
  u:   "client_uuid",
  m:   "match_id",
  t:   "frc_team_id",
  e:   "event_id",
  n:   "notes",
  s:   "status",
  ts:  "updated_at",
  afm: "auton_fuel_made",
  afx: "auton_fuel_missed",
  tfm: "teleop_fuel_made",
  tfx: "teleop_fuel_missed",
  efm: "endgame_fuel_made",
  efx: "endgame_fuel_missed",
  ac:  "auton_climb",
  ec:  "endgame_climb",
  dr:  "defense_rating",
  ap:  "auton_path",
}

// Reverse mapping: full key -> compact key
const REVERSE_KEY_MAP = Object.fromEntries(
  Object.entries(KEY_MAP).map(([k, v]) => [v, k])
)

/**
 * Encode a scouting entry object into a compact JSON string for QR code.
 *
 * @param {Object} entry - The scouting entry data. Expected shape:
 *   { client_uuid, match_id, frc_team_id, event_id, notes, status,
 *     updated_at, data: { auton_fuel_made, ..., auton_path } }
 * @returns {string} Compact JSON string
 */
export function encode(entry) {
  const data = entry.data || {}

  const payload = {
    v:   1,
    u:   entry.client_uuid,
    m:   entry.match_id,
    t:   entry.frc_team_id,
    e:   entry.event_id,
    s:   entry.status ?? 0,
    ts:  entry.updated_at || new Date().toISOString(),
  }

  // Only include notes if non-empty
  if (entry.notes) payload.n = entry.notes

  // Scoring data (use 0 defaults to omit zeros)
  if (data.auton_fuel_made)    payload.afm = data.auton_fuel_made
  if (data.auton_fuel_missed)  payload.afx = data.auton_fuel_missed
  if (data.teleop_fuel_made)   payload.tfm = data.teleop_fuel_made
  if (data.teleop_fuel_missed) payload.tfx = data.teleop_fuel_missed
  if (data.endgame_fuel_made)  payload.efm = data.endgame_fuel_made
  if (data.endgame_fuel_missed) payload.efx = data.endgame_fuel_missed

  // Boolean / enum fields
  if (data.auton_climb) payload.ac = 1
  if (data.endgame_climb && data.endgame_climb !== "None") {
    payload.ec = data.endgame_climb
  }
  if (data.defense_rating) payload.dr = data.defense_rating

  // Compact auton path encoding
  if (data.auton_path && Array.isArray(data.auton_path) && data.auton_path.length > 0) {
    payload.ap = compactPath(data.auton_path)
  }

  return JSON.stringify(payload)
}

/**
 * Decode a compact QR payload string back into a full scouting entry object.
 *
 * @param {string} jsonString - The compact JSON string from QR code
 * @returns {Object} Full scouting entry object with nested `data` hash
 */
export function decode(jsonString) {
  const payload = JSON.parse(jsonString)

  if (payload.v !== 1) {
    throw new Error(`Unsupported QR payload version: ${payload.v}`)
  }

  const entry = {
    client_uuid: payload.u,
    match_id:    payload.m,
    frc_team_id: payload.t,
    event_id:    payload.e,
    notes:       payload.n || "",
    status:      payload.s ?? 0,
    updated_at:  payload.ts,
    data: {
      auton_fuel_made:    payload.afm || 0,
      auton_fuel_missed:  payload.afx || 0,
      teleop_fuel_made:   payload.tfm || 0,
      teleop_fuel_missed: payload.tfx || 0,
      endgame_fuel_made:  payload.efm || 0,
      endgame_fuel_missed: payload.efx || 0,
      auton_climb:        payload.ac === 1,
      endgame_climb:      payload.ec || "None",
      defense_rating:     payload.dr || 0,
    }
  }

  // Expand auton path
  if (payload.ap && Array.isArray(payload.ap) && payload.ap.length > 0) {
    entry.data.auton_path = expandPath(payload.ap)
  } else {
    entry.data.auton_path = []
  }

  return entry
}

/**
 * Compact auton path strokes for QR encoding.
 * Converts [{x: 0.234, y: 0.567}, ...] per stroke into flat integer arrays
 * [234, 567, ...] and downsamples if too many points.
 *
 * @param {Array} strokes - Array of stroke arrays, each containing {x,y} objects
 * @returns {Array} Array of flat integer arrays
 */
function compactPath(strokes) {
  // Count total points
  let totalPoints = strokes.reduce((sum, stroke) => sum + (Array.isArray(stroke) ? stroke.length : 0), 0)

  // Downsample ratio (take every Nth point if over limit)
  const ratio = totalPoints > MAX_PATH_POINTS ? Math.ceil(totalPoints / MAX_PATH_POINTS) : 1

  return strokes
    .filter(stroke => Array.isArray(stroke) && stroke.length > 0)
    .map(stroke => {
      const sampled = ratio > 1 ? downsample(stroke, ratio) : stroke
      // Flatten to [x1,y1,x2,y2,...] with integer encoding
      const flat = []
      for (const point of sampled) {
        flat.push(Math.round((point.x || 0) * 1000))
        flat.push(Math.round((point.y || 0) * 1000))
      }
      return flat
    })
}

/**
 * Expand compact path data back into full stroke arrays with {x,y} objects.
 *
 * @param {Array} compactStrokes - Array of flat integer arrays [x1,y1,x2,y2,...]
 * @returns {Array} Array of stroke arrays with {x,y} objects
 */
function expandPath(compactStrokes) {
  return compactStrokes.map(flat => {
    const points = []
    for (let i = 0; i < flat.length; i += 2) {
      points.push({
        x: flat[i] / 1000,
        y: flat[i + 1] / 1000,
      })
    }
    return points
  })
}

/**
 * Downsample a stroke by taking every Nth point, always keeping first and last.
 */
function downsample(stroke, n) {
  if (stroke.length <= 2) return stroke
  const result = [stroke[0]]
  for (let i = n; i < stroke.length - 1; i += n) {
    result.push(stroke[i])
  }
  result.push(stroke[stroke.length - 1])
  return result
}
