class AddRoleToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :role_id, :integer, default: 2, null: false # 2 = Cliente por defecto
  end
end