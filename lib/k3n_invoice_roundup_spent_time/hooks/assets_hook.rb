module K3nInvoiceRoundupSpentTime
  module Hooks

	  class IncludeJavascriptsHook < Redmine::Hook::ViewListener
		include ActionView::Helpers::TagHelper
		render_on :view_layouts_base_html_head, :partial => "k3n_invoice_roundup_spent_time/html_head"

		#def view_layouts_base_html_head(context)
		  #html = "\n<!-- [k3n_invoice_roundup_spent_time] -->\n"
		  #html << stylesheet_link_tag(:application, :plugin => 'k3n_invoice_roundup_spent_time')
		  #html << "\n"
		  #html << javascript_include_tag(:application, :plugin => 'k3n_invoice_roundup_spent_time')
		  #html << "\n<!-- [k3n_invoice_roundup_spent_time] -->\n"
		  #return html
		  
		#end
	  end

  end
end