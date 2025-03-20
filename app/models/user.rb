class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :cart, dependent: :destroy 

  ADMIN = 1
  CLIENT = 2

  validates :role, inclusion: { in: [ADMIN, CLIENT] }

  after_initialize :set_default_role, if: :new_record?

  # Método para obtener el rol legible
  def role_name
    case role
    when ADMIN
      'admin'
    when CLIENT
      'client'
    else
      'unknown'
    end
  end

  private

  def set_default_role
    self.role ||= CLIENT # Cliente por defecto
  end
  
end

