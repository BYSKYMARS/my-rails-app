class RenameRoleIdToRoleInUsers < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :role_id, :role
  end
end

