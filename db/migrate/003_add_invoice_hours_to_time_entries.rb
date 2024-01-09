class AddInvoiceHoursToTimeEntries < ActiveRecord::Migration
  def self.up
    add_column :time_entries, :invoice_hours, :float
  end

  def self.down
    remove_column :time_entries, :invoice_hours
  end
end
