class AddCodigoToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :codigo, :string
  end
end
