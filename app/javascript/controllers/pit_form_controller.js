import { Controller } from "@hotwired/stimulus"

/**
 * Handles conditional visibility in the pit scouting form:
 * - Pivot motor select: shown only when drivetrain is "Swerve"
 * - Intake type (mechanism): shown only when over-bumper is checked
 * - "Other" text inputs: shown when "Other" is selected for intake mechanism or indexer
 */
export default class extends Controller {
  static targets = [
    "pivotMotorGroup",
    "drivetrainSelect",
    "overBumperCheckbox",
    "intakeTypeGroup",
    "intakeMechanismSelect",
    "intakeMechanismOther",
    "indexerSelect",
    "indexerOther"
  ]

  connect() {
    this.#updatePivotMotor()
    this.#updateIntakeType()
    this.#updateIntakeMechanismOther()
    this.#updateIndexerOther()
  }

  // --- Actions ---

  drivetrainChanged() {
    this.#updatePivotMotor()
  }

  intakeChanged() {
    this.#updateIntakeType()
  }

  intakeMechanismChanged() {
    this.#updateIntakeMechanismOther()
  }

  indexerChanged() {
    this.#updateIndexerOther()
  }

  // --- Private ---

  #updatePivotMotor() {
    if (!this.hasPivotMotorGroupTarget || !this.hasDrivetrainSelectTarget) return
    const isSwerve = this.drivetrainSelectTarget.value === "Swerve"
    this.pivotMotorGroupTarget.classList.toggle("hidden", !isSwerve)
  }

  #updateIntakeType() {
    if (!this.hasIntakeTypeGroupTarget || !this.hasOverBumperCheckboxTarget) return
    const overBumperChecked = this.overBumperCheckboxTarget.checked
    this.intakeTypeGroupTarget.classList.toggle("hidden", !overBumperChecked)
  }

  #updateIntakeMechanismOther() {
    if (!this.hasIntakeMechanismOtherTarget || !this.hasIntakeMechanismSelectTarget) return
    const isOther = this.intakeMechanismSelectTarget.value === "Other"
    this.intakeMechanismOtherTarget.classList.toggle("hidden", !isOther)
  }

  #updateIndexerOther() {
    if (!this.hasIndexerOtherTarget || !this.hasIndexerSelectTarget) return
    const isOther = this.indexerSelectTarget.value === "Other"
    this.indexerOtherTarget.classList.toggle("hidden", !isOther)
  }
}
