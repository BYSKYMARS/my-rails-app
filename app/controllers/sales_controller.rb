class SalesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin

  def index
    if params[:query].present?
      @sales = Sale.where("email ILIKE ? OR product_name ILIKE ? OR order_id::text ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%").order(date_time: :desc)
    else
      @sales = Sale.order(date_time: :desc) # Muestra las órdenes más recientes primero
    end
  end

  private

  def authorize_admin
    unless current_user.role == User::ADMIN
      redirect_to root_path, alert: "No tienes permisos para acceder a esta página."
    end
  end
end

