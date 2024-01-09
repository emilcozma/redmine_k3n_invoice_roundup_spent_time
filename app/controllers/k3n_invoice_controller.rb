# Redmine - project management software
# Copyright (C) 2006-2017  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class K3nInvoiceController < ApplicationController
  before_action :find_time_entry, :only => [:update]
  before_action :check_editability, :only => [:update]
  #before_action :authorize, :only => [:update]

  accept_api_auth :update

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :issues
  include TimelogHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :queries
  include QueriesHelper

  def update
    
    old_invoice_hours = @time_entry.invoice_hours
	total_invoice_hours = params[:total_invoice_hours].to_hours
    @time_entry.safe_attributes = params[:time_entry]
	if @time_entry.invoice_hours < @time_entry.hours
		@time_entry.invoice_hours = (@time_entry.hours * 4).ceil.fdiv(4)
	end

    if @time_entry.save
	  if @time_entry.invoice_hours > old_invoice_hours
	    invoice_hours_diff = format_hours(@time_entry.invoice_hours - old_invoice_hours)
	  else
		invoice_hours_diff = '-' + format_hours(old_invoice_hours - @time_entry.invoice_hours)
	  end
	  total_invoice_hours = format_hours(total_invoice_hours + (@time_entry.invoice_hours - old_invoice_hours))
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default project_time_entries_path(@time_entry.project)
        }
        format.api  { render :json => {:time_entry => @time_entry, :invoice_hours => format_hours(@time_entry.invoice_hours), :invoice_hours_diff => invoice_hours_diff , :total_invoice_hours => total_invoice_hours,  :status => :updated} }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api  { render_validation_errors(@time_entry) }
      end
    end
  end

private
  def find_time_entry
    @time_entry = TimeEntry.find(params[:id])
    @project = @time_entry.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_editability
    unless @time_entry.editable_by?(User.current)
      render_403
      return false
    end
  end

  def find_time_entries
    @time_entries = TimeEntry.where(:id => params[:id] || params[:ids]).
      preload(:project => :time_entry_activities).
      preload(:user).to_a

    raise ActiveRecord::RecordNotFound if @time_entries.empty?
    raise Unauthorized unless @time_entries.all? {|t| t.editable_by?(User.current)}
    @projects = @time_entries.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_issue
    if params[:issue_id].present?
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    else
      find_optional_project
    end
  end

  def find_optional_project
    if params[:project_id].present?
      @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Returns the TimeEntry scope for index and report actions
  def time_entry_scope(options={})
    @query.results_scope(options)
  end

  def retrieve_time_entry_query
    retrieve_query(TimeEntryQuery, false)
  end
end
