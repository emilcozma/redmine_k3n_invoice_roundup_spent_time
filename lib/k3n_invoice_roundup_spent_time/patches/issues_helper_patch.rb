require_dependency 'issues_helper'

module K3nInvoiceRoundupSpentTime
  module Patches
    module IssuesHelperPatch
	  include Redmine::I18n
	  def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
		  def issue_offer_hours_details(issue)
			if issue.total_offer_hours.present?
			  if issue.total_offer_hours == issue.offer_hours
				l_hours_short(issue.offer_hours)
			  else
				s = issue.offer_hours.present? ? l_hours_short(issue.offer_hours) : ""
				s << " (#{l(:label_total)}: #{l_hours_short(issue.total_offer_hours)})"
				s.html_safe
			  end
			end
		  end

		  def issue_invoice_hours_details(issue)
			if issue.total_invoice_hours > 0
			  path = project_time_entries_path(issue.project, :issue_id => "~#{issue.id}")

			  if issue.total_invoice_hours == issue.invoice_hours
				link_to(l_hours_short(issue.invoice_hours), path)
			  else
				s = issue.invoice_hours > 0 ? l_hours_short(issue.invoice_hours) : ""
				s << " (#{l(:label_total)}: #{link_to l_hours_short(issue.total_invoice_hours), path})"
				s.html_safe
			  end
			end
		  end
        end
      end
    end
  end
end

unless IssuesHelper.included_modules.include?(K3nInvoiceRoundupSpentTime::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, K3nInvoiceRoundupSpentTime::Patches::IssuesHelperPatch)
end