require_dependency 'query'

module K3nInvoiceRoundupSpentTime
  module Patches

	module QueryPatch
		def self.included(base) # :nodoc:
        base.class_eval do
          unloadable
		  def total_with_scope(column, scope)
			unless column.is_a?(QueryColumn)
			  column = column.to_sym
			  column = available_totalable_columns.detect {|c| c.name == column}
			end
			if column.is_a?(QueryCustomFieldColumn)
			  custom_field = column.custom_field
			  send "total_for_custom_field", custom_field, scope
			elsif column.is_a?(QueryAssociationColumn)
			  send "total_for_" + "#{column.name}".gsub('.', '_'), scope
			else			  
			  send "total_for_#{column.name}", scope
			end
		  #rescue ::ActiveRecord::StatementInvalid => e
			#raise StatementInvalid.new(e.message)
		  end
		end
	  end
	end
  end
end

unless Query.included_modules.include?(K3nInvoiceRoundupSpentTime::Patches::QueryPatch)
  Query.send(:include, K3nInvoiceRoundupSpentTime::Patches::QueryPatch)
end