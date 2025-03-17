class RemoveImagenReferencialFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :imagen_referencial, :string
  end
end
