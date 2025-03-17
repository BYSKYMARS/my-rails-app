class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :nombre
      t.text :descripcion
      t.integer :stock
      t.decimal :precio
      t.string :imagen_referencial
      t.string :marca

      t.timestamps
    end
  end
end
