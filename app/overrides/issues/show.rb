#Deface::Override.new(:virtual_path => "issues/show", 
#                     :name => "issues_show_offer_hours",
#                     :insert_before=> "erb[loud]:contains(\"if User.current.allowed_to?(:view_time_entries, @project) && @issue.total_spent_hours > 0\")",
#                     :text => "<%=
#						unless @issue.disabled_core_fields.include?('offer_hours')
#						  rows.right l(:field_offer_hours), issue_estimated_hours_details(@issue), :class => 'offer_hours'
#						end
#						%>")