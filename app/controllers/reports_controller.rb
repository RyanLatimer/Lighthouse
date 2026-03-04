class ReportsController < ApplicationController
  before_action :require_event!
  before_action :set_report, only: %i[show edit update destroy generate]

  def index
    @reports = policy_scope(Report)
                 .where(event: current_event)
                 .order(updated_at: :desc)
  end

  def show
    authorize @report
    @report_data = ReportBuilderService.new(@report).generate
  end

  def new
    @report = Report.new(event: current_event)
    authorize @report
    @teams = FrcTeam.at_event(current_event).order(:team_number)
  end

  def create
    @report = current_user.reports.build(report_params)
    @report.event = current_event
    authorize @report

    if @report.save
      redirect_to @report, notice: "Report created."
    else
      @teams = FrcTeam.at_event(current_event).order(:team_number)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @report
    @teams = FrcTeam.at_event(current_event).order(:team_number)
  end

  def update
    authorize @report

    if @report.update(report_params)
      redirect_to @report, notice: "Report updated."
    else
      @teams = FrcTeam.at_event(current_event).order(:team_number)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @report
    @report.destroy!
    redirect_to reports_path, notice: "Report deleted.", status: :see_other
  end

  def generate
    authorize @report, :update?
    @report_data = ReportBuilderService.new(@report).generate
    @report.update(cached_data: @report_data, last_generated_at: Time.current)
    redirect_to @report, notice: "Report regenerated."
  end

  private

  def set_report
    @report = Report.find(params[:id])
  end

  def report_params
    params.require(:report).permit(
      :name,
      config: {}
    )
  end
end
