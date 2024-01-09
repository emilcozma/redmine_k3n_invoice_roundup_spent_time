# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

#custom routes for this plugin
RedmineApp::Application.routes.draw do
  match '/k3n_invoice/update/:id' => 'k3n_invoice#update', :via => [:get, :post, :put, :patch], :as => 'k3n_invoice_update'
end
