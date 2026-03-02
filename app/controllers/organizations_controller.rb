class OrganizationsController < ApplicationController
  skip_after_action :pundit_verify
  before_action :set_organization, only: %i[show edit update]

  def show
    @members = @organization.memberships.includes(:user).order(:role)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      # Make the creator the owner
      Membership.create!(user: current_user, organization: @organization, role: :owner)
      session[:current_organization_id] = @organization.id
      redirect_to root_path, notice: "Organization created. You are the owner."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless current_user.admin_of?(@organization)
      redirect_to root_path, alert: "Not authorized."
    end
  end

  def update
    unless current_user.admin_of?(@organization)
      redirect_to root_path, alert: "Not authorized."
      return
    end

    if @organization.update(organization_params)
      redirect_to @organization, notice: "Organization updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def switch
    org = current_user.organizations.find_by(id: params[:id])
    if org
      session[:current_organization_id] = org.id
      redirect_to root_path, notice: "Switched to #{org.name}."
    else
      redirect_to root_path, alert: "Organization not found."
    end
  end

  def invite
    @organization = Organization.find(params[:id])
    unless current_user.lead_of?(@organization)
      redirect_to root_path, alert: "Not authorized."
      return
    end

    user = User.find_by(email: params[:email])
    if user
      role = params[:role].present? ? params[:role].to_sym : :scout
      Membership.find_or_create_by!(user: user, organization: @organization) do |m|
        m.role = role
      end
      redirect_to @organization, notice: "#{user.full_name} has been invited."
    else
      redirect_to @organization, alert: "No user found with that email."
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :team_number)
  end
end
