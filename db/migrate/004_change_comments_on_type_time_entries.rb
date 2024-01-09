class ChangeCommentsOnTypeTimeEntries < ActiveRecord::Migration
  def self.up
    change_column :time_entries, :comments, :text
  end

  def self.down
    change_column :time_entries, :comments, :string
  end
end
