class Cart < ApplicationRecord
    belongs_to :user  # Establece que el carrito pertenece a un usuario
    has_many :line_items, dependent: :destroy
  end