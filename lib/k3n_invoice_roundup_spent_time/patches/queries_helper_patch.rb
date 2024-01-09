
module K3nInvoiceRoundupSpentTime
  module Patches

	module QueriesHelperPatch
		def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
		  def total_tag(column, value)
			label = content_tag('span', "#{column.caption}:")
			value = if [:hours, :spent_hours, :total_spent_hours, :estimated_hours, :invoice_hours, :total_invoice_hours].include? column.name
			  format_hours(value)
			else
			  format_object(value)
			end
			value = content_tag('span', value, :class => 'value')
			content_tag('span', label + " " + value, :class => "total-for-#{column.name.to_s.dasherize}")
		  end
		  def column_value(column, item, value)
			case column.name
			when :id
			  link_to value, issue_path(item)
			when :subject
			  link_to value, issue_path(item)
			when :parent
			  value ? (value.visible? ? link_to_issue(value, :subject => false) : "##{value.id}") : ''
			when :description
			  item.description? ? content_tag('div', textilizable(item, :description), :class => "wiki") : ''
			when :last_notes
			  item.last_notes.present? ? content_tag('div', textilizable(item, :last_notes), :class => "wiki") : ''
			when :done_ratio
			  progress_bar(value)
			when :relations
			  content_tag('span',
				value.to_s(item) {|other| link_to_issue(other, :subject => false, :tracker => false)}.html_safe,
				:class => value.css_classes_for(item))
			when :hours, :estimated_hours
			  format_hours(value)
			when :invoice_hours, :total_invoice_hours
			  if value.nil?
				value = (item.hours * 4).ceil.fdiv(4)
			  end
			  format_hours(value)
			when :spent_hours
			  link_to_if(value > 0, format_hours(value), project_time_entries_path(item.project, :issue_id => "#{item.id}"))
			when :total_spent_hours
			  link_to_if(value > 0, format_hours(value), project_time_entries_path(item.project, :issue_id => "~#{item.id}"))
			when :attachments
			  value.to_a.map {|a| format_object(a)}.join(" ").html_safe
			else
			  format_object(value)
			end
		  end
        end
      end
	end

  end
end

unless QueriesHelper.included_modules.include?(K3nInvoiceRoundupSpentTime::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, K3nInvoiceRoundupSpentTime::Patches::QueriesHelperPatch)
end
