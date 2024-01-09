Deface::Override.new(:virtual_path => "issues/_attributes", 
                     :name => "issues_attributes_offer_hours",
					 :original => "15b28c4301527f8c87de2fd774b611f65079fc21",
                     :insert_bottom => ".splitcontentright",
                     :text => '<p><%= f.hours_field :offer_hours %> <%= l(:field_hours) %></p>')