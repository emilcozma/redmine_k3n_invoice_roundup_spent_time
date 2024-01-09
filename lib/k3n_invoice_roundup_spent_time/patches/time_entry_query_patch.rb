require_dependency 'time_entry_query'

module K3nInvoiceRoundupSpentTime
  module Patches
	module TimeEntryQueryPatch
	  def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
          # new method
		  self.available_columns.push(
			QueryColumn.new(:invoice_hours, :sortable => "IF(#{TimeEntry.table_name}.invoice_hours > 0, #{TimeEntry.table_name}.invoice_hours, CEIL(#{TimeEntry.table_name}.hours * 4) / 4.0)", :totalable => true),
			QueryAssociationColumn.new(:issue, :offer_hours, :caption => :field_offer_hours, :sortable => "#{Issue.table_name}.offer_hours", :totalable => true),
		  )

		  self.available_columns.map do |e|
		    if e.name == :issue
			  self.available_columns.delete(e)
			end
		  end

		  self.available_columns.push(
		    QueryColumn.new(:issue, :sortable => "#{Issue.table_name}.id", :groupable => true)
		  )

		  def default_columns_names
		    @default_columns_names ||= begin
			  default_columns = [:spent_on, :user, :activity, :issue, :comments, :hours, :invoice_hours]
			  
			  project.present? ? default_columns : [:project] | default_columns
			end
	      end
		  
		  def default_totalable_names
		    [:hours, :invoice_hours]
		  end

		  # Returns sum of all the spent hours
		  def total_for_hours(scope)
			map_total(scope.sum(:hours)) {|t| (t.to_f * 100).ceil.fdiv(100).round(2)}
		  end

		  # Returns sum of all the spent hours
		  def total_for_invoice_hours(scope)
			map_total(scope.sum("IF(#{TimeEntry.table_name}.invoice_hours > 0, #{TimeEntry.table_name}.invoice_hours, CEIL(#{TimeEntry.table_name}.hours * 4) / 4.0)")) {|t| t.to_f.round(2)}
		  end

		  def total_for_estimated_hours(scope)
            #map_total(scope.sum(:estimated_hours)) {|t| (t.to_f).round(2)}
			#puts scope.sum("#{Issue.table_name}.estimated_hours), COUNT(DISTINCT #{Issue.table_name}.id")
			#puts scope.select("GROUP_CONCAT(DISTINCT #{Issue.table_name}.id) as contact_issues_id").to_sql
			total = scope.sum(:estimated_hours)
			if total.is_a?(Hash)
			  total.keys.each do |k| 
			    if k.nil?
					total[k] = total[k].to_f.round(2)
				else
					if k.is_a?(Issue)
						total[k] = k.estimated_hours.to_f.round(2)
					end
			    end
			  end
			else
			  total = 0
			  totalArray = {}
			  scope.each do |item| 
				if !item.issue.nil?
					if !item.issue.estimated_hours.nil?
						totalArray[item.issue.id] = item.issue.estimated_hours
					end
				end
			  end
			  totalArray.each do |k,item|
			    total = total + item
			  end
			  total = total.to_f.round(2)
			end
			total
          end

		  # Returns sum of all the spent hours
		  def total_for_issue_offer_hours(scope)
		    #map_total(scope.sum("#{Issue.table_name}.offer_hours")) {|t| (t.to_f).round(2)}
			total = scope.sum("#{Issue.table_name}.offer_hours")
			if total.is_a?(Hash)
			  total.keys.each do |k| 
			    if k.nil?
					total[k] = total[k].to_f.round(2)
				else
					if k.is_a?(Issue)
						total[k] = k.offer_hours.to_f.round(2)
					end					
			    end
			  end
			else
			  total = 0
			  totalArray = {}
			  scope.each do |item|
				if !item.issue.nil?
					if !item.issue.offer_hours.nil?
						totalArray[item.issue.id] = item.issue.offer_hours
					end
				end
			  end
			  totalArray.each do |k,item|
			    total = total + item
			  end
			  total = total.to_f.round(2)
			end
			total
		  end

        end
      end
    end

  end
end


unless TimeEntryQuery.included_modules.include?(K3nInvoiceRoundupSpentTime::Patches::TimeEntryQueryPatch)
  TimeEntryQuery.send(:include, K3nInvoiceRoundupSpentTime::Patches::TimeEntryQueryPatch)
end