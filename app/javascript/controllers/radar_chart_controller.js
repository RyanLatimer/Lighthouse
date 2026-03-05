import { Controller } from "@hotwired/stimulus"

// Radar chart using Chart.js (already bundled via chartkick)
// Expects JSON values for teams and event-wide percentile data.
//
// Usage:
//   data-controller="radar-chart"
//   data-radar-chart-teams-value='[{"name":"#254","color":"#f97316","values":{"avg_total_points":85.2,...}}]'
//   data-radar-chart-all-values-value='{"avg_total_points":[10,20,30,...],...}'

const AXES = [
  { key: "avg_total_points", label: "Points" },
  { key: "avg_auton_points", label: "Auto" },
  { key: "fuel_accuracy_pct", label: "Accuracy" },
  { key: "avg_climb_points", label: "Climb" },
  { key: "avg_defense_rating", label: "Defense" }
]

export default class extends Controller {
  static values = {
    teams: { type: Array, default: [] },
    allValues: { type: Object, default: {} }
  }

  connect() {
    this.#waitForChartJS()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  teamsValueChanged() {
    if (this.chart) this.#render()
  }

  // Chart.js might load asynchronously via importmap; poll briefly
  #waitForChartJS(attempts = 0) {
    if (typeof Chart !== "undefined") {
      this.#render()
    } else if (attempts < 20) {
      setTimeout(() => this.#waitForChartJS(attempts + 1), 100)
    }
  }

  #render() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }

    const teams = this.teamsValue
    const allValues = this.allValuesValue
    if (!teams.length) return

    const canvas = this.element.querySelector("canvas")
    if (!canvas) return

    const datasets = teams.map(team => {
      const percentiles = AXES.map(axis => {
        const rawValue = team.values[axis.key]
        if (rawValue === null || rawValue === undefined || rawValue === "") {
          return 0
        }
        const teamVal = parseFloat(rawValue)
        if (isNaN(teamVal)) {
          return 0
        }
        const allVals = (allValues[axis.key] || []).map(Number).filter(v => !isNaN(v))
        return this.#percentileRank(teamVal, allVals)
      })

      const color = team.color
      return {
        label: team.name,
        data: percentiles,
        borderColor: color,
        backgroundColor: this.#hexToRgba(color, 0.15),
        borderWidth: 2,
        pointBackgroundColor: color,
        pointBorderColor: color,
        pointRadius: 4,
        pointHoverRadius: 6
      }
    })

    this.chart = new Chart(canvas, {
      type: "radar",
      data: {
        labels: AXES.map(a => a.label),
        datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        scales: {
          r: {
            beginAtZero: true,
            min: 0,
            max: 100,
            ticks: {
              display: false,
              stepSize: 20
            },
            grid: {
              color: "#374151"
            },
            angleLines: {
              color: "#374151"
            },
            pointLabels: {
              color: "#d1d5db",
              font: { size: 13, weight: "bold" }
            }
          }
        },
        plugins: {
          legend: {
            position: "bottom",
            labels: {
              color: "#d1d5db",
              padding: 16,
              usePointStyle: true,
              pointStyle: "circle",
              font: { size: 12 }
            }
          },
          tooltip: {
            callbacks: {
              label: (ctx) => {
                const axisKey = AXES[ctx.dataIndex].key
                const team = teams[ctx.datasetIndex]
                const rawValue = team.values[axisKey]
                const isMissing = rawValue === null || rawValue === undefined || rawValue === ""
                const raw = isMissing ? 0 : parseFloat(rawValue) || 0
                const pct = ctx.parsed.r.toFixed(0)
                let rawStr
                
                if (isMissing) {
                  rawStr = "N/A"
                } else if (axisKey === "fuel_accuracy_pct") {
                  rawStr = `${raw.toFixed(1)}%`
                } else if (axisKey === "avg_defense_rating") {
                  rawStr = `${raw.toFixed(1)}/5`
                } else {
                  rawStr = raw.toFixed(1)
                }
                
                return `${team.name}: ${rawStr} (${pct}%)`
              }
            }
          }
        }
      }
    })
  }

  // Min-max normalization: best value at event = 100, worst = 5 (offset from center)
  #percentileRank(value, allValues) {
    if (!allValues.length) return 50
    const min = Math.min(...allValues)
    const max = Math.max(...allValues)
    if (max === min) return 50
    const normalized = (value - min) / (max - min)
    return 5 + normalized * 95
  }

  #hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }
}
