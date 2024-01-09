Deface::Override.new(:virtual_path => "timelog/_list", 
                     :name => "timelog_list_allow_edit_invoice_time",
					 :original => 'b776d56cd775b72c218d68517a93edec16808914',
                     :replace => "td.checkbox",
                     :text => "<td class=\"checkbox hide-when-print <%= entry.editable_by?(User.current) ? 'allow-edit-invoice-time' : '' %>\"><%= ::Temple::Utils.escape_html_safe((check_box_tag('ids[]', entry.id, false, id: nil))) %></td>")