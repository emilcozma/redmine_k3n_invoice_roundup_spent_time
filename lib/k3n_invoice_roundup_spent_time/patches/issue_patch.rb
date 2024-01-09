require_dependency 'issue'

module K3nInvoiceRoundupSpentTime
  module Patches
    module IssuePatch
	  include Redmine::I18n
	  def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
		  validates :offer_hours, :numericality => {:greater_than_or_equal_to => 0, :allow_nil => true, :message => :invalid}
		  safe_attributes :offer_hours

		  def offer_hours
		    h = read_attribute(:offer_hours)
		    if h.is_a?(Float)
			  rounded = ((h * 100).ceil / 100.0).to_f
			else
			  h
			end
		  end
		  def offer_hours=(h)
		    write_attribute :offer_hours, (h.is_a?(String) ? (h.to_hours || h) : h)
		  end

		  def total_offer_hours
			if leaf?
			  offer_hours
			else
			  @total_offer_hours ||= self_and_descendants.sum(:offer_hours)
			end
		  end

		  # Preloads visible invoice time for a collection of issues
		  def self.load_visible_invoice_hours(issues, user=User.current)
			if issues.any?
			  hours_by_issue_id = TimeEntry.visible(user).where(:issue_id => issues.map(&:id)).group(:issue_id).sum(:hours)
			  issues.each do |issue|
				issue.instance_variable_set "@invoice_hours", (hours_by_issue_id[issue.id] || 0.0)
			  end
			end
		  end

		  # Preloads visible total invoice time for a collection of issues
		  def self.load_visible_total_invoice_hours(issues, user=User.current)
			if issues.any?
			  hours_by_issue_id = TimeEntry.visible(user).joins(:issue).
				joins("JOIN #{Issue.table_name} parent ON parent.root_id = #{Issue.table_name}.root_id" +
				  " AND parent.lft <= #{Issue.table_name}.lft AND parent.rgt >= #{Issue.table_name}.rgt").
				where("parent.id IN (?)", issues.map(&:id)).group("parent.id").sum("IF(#{TimeEntry.table_name}.invoice_hours > 0, #{TimeEntry.table_name}.invoice_hours, CEIL(#{TimeEntry.table_name}.hours * 4) / 4.0)")
			  issues.each do |issue|
				issue.instance_variable_set "@total_invoice_hours", (hours_by_issue_id[issue.id] || 0.0)
			  end
			end
		  end

		  # Returns the number of hours invoice on this issue
		  def invoice_hours
			@invoice_hours ||= time_entries.sum("IF(#{TimeEntry.table_name}.invoice_hours > 0, #{TimeEntry.table_name}.invoice_hours, CEIL(#{TimeEntry.table_name}.hours * 4) / 4.0)") || 0.0
		  end

		  # Returns the total number of hours invoice on this issue and its descendants
		  def total_invoice_hours
			@total_invoice_hours ||= if leaf?
			  invoice_hours
			else
			  self_and_descendants.joins(:time_entries).sum("IF(#{TimeEntry.table_name}.invoice_hours > 0, #{TimeEntry.table_name}.invoice_hours, CEIL(#{TimeEntry.table_name}.hours * 4) / 4.0)").to_f || 0.0
			end
		  end
        end
      end
    end
	module IssueQueryPatch
	  def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
          # new method
		  self.available_columns.push(QueryColumn.new(:offer_hours, :sortable => "#{Issue.table_name}.offer_hours", :totalable => true))
		  self.available_columns.push(QueryColumn.new(:invoice_hours, :sortable => "COALESCE((SELECT SUM(CEIL(#{TimeEntry.table_name}.hours * 4) / 4.0) FROM #{TimeEntry.table_name}" +
        " JOIN #{Project.table_name} ON #{Project.table_name}.id = #{TimeEntry.table_name}.project_id" +
        " WHERE (#{TimeEntry.visible_condition(User.current)}) AND #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id), 0)", :totalable => false))
		self.available_columns.push(QueryColumn.new(:total_invoice_hours, :sortable => "COALESCE((SELECT SUM(CEIL(#{TimeEntry.table_name}.hours * 4) / 4.0) FROM #{TimeEntry.table_name}" +
        " JOIN #{Project.table_name} ON #{Project.table_name}.id = #{TimeEntry.table_name}.project_id" +
        " JOIN #{Issue.table_name} subtasks ON subtasks.id = #{TimeEntry.table_name}.issue_id" +
        " WHERE (#{TimeEntry.visible_condition(User.current)})" +
        " AND subtasks.root_id = #{Issue.table_name}.root_id AND subtasks.lft >= #{Issue.table_name}.lft AND subtasks.rgt <= #{Issue.table_name}.rgt), 0)", :totalable => false))

		  def total_for_offer_hours(scope)
			map_total(scope.sum(:offer_hours)) {|t| t.to_f.round(2)}
		  end
		  
        end
      end
    end
	module QueriesHelperPatch
		def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
		  
        end
      end
	end
  end
end

unless Issue.included_modules.include?(K3nInvoiceRoundupSpentTime::Patches::IssuePatch)
  Issue.send(:include, K3nInvoiceRoundupSpentTime::Patches::IssuePatch)
end

unless IssueQuery.included_modules.include?(K3nInvoiceRoundupSpentTime::Patches::IssueQueryPatch)
  IssueQuery.send(:include, K3nInvoiceRoundupSpentTime::Patches::IssueQueryPatch)
end