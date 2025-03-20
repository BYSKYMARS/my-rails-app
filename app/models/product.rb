class Product < ApplicationRecord
    before_create :generate_codigo
    before_save :update_codigo, if: :nombre_changed?
    has_many :line_items, dependent: :destroy
    has_one_attached :imagen_referencial  # Asocia una imagen al producto
    validates :imagen_referencial, presence: true
    validates :nombre, presence: true
    validates :descripcion, presence: true
    validates :stock, numericality: { greater_than_or_equal_to: 0 }
    validates :precio, numericality: { greater_than: 0 }
    validates :marca, presence: true
    private

    def generate_codigo
      self.codigo = "#{nombre[0,2].upcase}000#{id}"
    end

    def update_codigo
      self.codigo = "#{nombre[0, 2].upcase}000#{id}"
    end
  end