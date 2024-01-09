require 'redmine'

Redmine::Plugin.register :k3n_invoice_roundup_spent_time do
  name 'keeen invoice roundup spent time with step of 15 min'
  author 'Emil COZMA'
  description "This is a really simple plugin which round up your spent time with step of 15 min."
  version '1.0.0'
  author_url 'https://www.cozma.es'
  project_module :time_tracking do
	permission :edit_invoice_time_entries, {:timelog => [:edit, :update, :destroy, :bulk_edit, :bulk_update], :k3n_invoice => [:update]}, :require => :member
  end      
end

Rails.application.paths["app/overrides"] ||= []
Rails.application.paths["app/overrides"] << File.expand_path("../app/overrides", __FILE__)

ActiveSupport::Reloader.to_prepare do
  require 'k3n_invoice_roundup_spent_time'
end