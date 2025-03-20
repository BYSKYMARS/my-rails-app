class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Redirige a la página de productos después de iniciar sesión
  def after_sign_in_path_for(resource)
    products_path
  end

  # Redirige al inicio de sesión después de cerrar sesión
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  # Permite parámetros adicionales si los estás utilizando en el formulario de Devise
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:nombre, :apellido, :direccion, :telefono]) # Ejemplo
    devise_parameter_sanitizer.permit(:account_update, keys: [:nombre, :apellido, :direccion, :telefono]) # Ejemplo
  end
end
