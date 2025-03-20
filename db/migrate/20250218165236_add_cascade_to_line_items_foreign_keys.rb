class AddCascadeToLineItemsForeignKeys < ActiveRecord::Migration[6.0]
  def change
    # Modificar la clave foránea de productos en la tabla line_items
    remove_foreign_key :line_items, :products
    add_foreign_key :line_items, :products, on_delete: :cascade

    # Modificar la clave foránea de carts en la tabla line_items
    remove_foreign_key :line_items, :carts
    add_foreign_key :line_items, :carts, on_delete: :cascade
  end
end
