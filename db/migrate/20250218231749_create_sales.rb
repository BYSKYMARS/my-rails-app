class CreateSales < ActiveRecord::Migration[8.0]
  def change
    create_table :sales do |t|
      t.integer :order_id
      t.string :email
      t.string :product_cod
      t.string :product_name
      t.decimal :price
      t.integer :quantity
      t.decimal :total
      t.datetime :date_time

      t.timestamps
    end
  end
end
