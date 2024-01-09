require_dependency 'time_entry'

module K3nInvoiceRoundupSpentTime
  module Patches
    module TimeEntryPatch
	  include Redmine::I18n
	  def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
		  safe_attributes :invoice_hours
		  def hours
		    h = read_attribute(:hours)
		    if h.is_a?(Float)
			  rounded = ((h * 100).ceil.fdiv(100)).to_f
			else
			  h
			end
		  end

		  def hours=(h)
		    write_attribute :hours, (h.is_a?(String) ? (h.to_hours || h) : h)
		    if !h.nil? && !h.empty?
			  #round up the hours for customer invoice
			  invoice_hours = (h.is_a?(String) ? (((h.to_hours * 4).ceil.fdiv(4)) || ((h * 4).ceil.fdiv(4))) : ((h * 4).ceil.fdiv(4)))
			  invoice_hours_value = read_attribute(:invoice_hours)
			  if invoice_hours_value.nil? || invoice_hours_value < invoice_hours
			    write_attribute :invoice_hours, (invoice_hours)
			  end
			end
		  end

          # new method
		  def invoice_hours=(h)
			invoice_hours = (h.is_a?(String) ? ((h.to_hours * 4).ceil.fdiv(4) || (h * 4).ceil.fdiv(4)) : (h * 4).ceil.fdiv(4))
			h = ((invoice_hours < self.hours) ? self.hours : invoice_hours)
			write_attribute :invoice_hours, (h.is_a?(String) ? ((h.to_hours * 4).ceil.fdiv(4) || (h * 4).ceil.fdiv(4)) : (h * 4).ceil.fdiv(4))
		  end

		  def invoice_hours
		    h = read_attribute(:invoice_hours)
		    if h.is_a?(Float)
			  rounded = ((h * 100).ceil.fdiv(100)).to_f
			else
			  (self.hours * 4).ceil.fdiv(4)
			end
		  end

		  # Returns true if the time entry can be edited by usr, otherwise false
		  def invoice_entry_editable_by?(usr)
			visible?(usr) && (
			  (usr == user && usr.allowed_to?(:edit_invoice_time_entries, project))
			)
		  end
        end
      end
    end

  end
end

unless TimeEntry.included_modules.include?(K3nInvoiceRoundupSpentTime::Patches::TimeEntryPatch)
  TimeEntry.send(:include, K3nInvoiceRoundupSpentTime::Patches::TimeEntryPatch)
end
