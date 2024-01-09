class AddOfferHoursToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :offer_hours, :float
  end

  def self.down
    remove_column :issues, :offer_hours
  end
end