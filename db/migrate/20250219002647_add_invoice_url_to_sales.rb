class AddInvoiceUrlToSales < ActiveRecord::Migration[8.0]
  def change
    add_column :sales, :invoice_url, :string
  end
end
