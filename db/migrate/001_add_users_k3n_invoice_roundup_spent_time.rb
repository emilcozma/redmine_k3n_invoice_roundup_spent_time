class AddUsersK3nInvoiceRoundupSpentTime < ActiveRecord::Migration
  def self.up
    add_column :users, :k3n_invoice_time, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :k3n_invoice_time
  end
end
