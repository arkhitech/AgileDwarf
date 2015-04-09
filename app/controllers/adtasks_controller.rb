class AdtasksController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :clear_flash, only: [:list] # For muting flash messages about successful issue saving after blocked status updating

  def list
    # data for filters
    @sprints = Sprints.open_sprints(@project)
    @project_id = @project.id
    @assignables = @project.assignable_users
    @assignables_list = {}
    @project.assignable_users.each{|u| @assignables_list[u.id] = u.name}
    # Support Assign to nobody
    @assignables_list[""] = ""
    @available_custom_fields = SprintsTasks.available_custom_fields(@project)
    @available_custom_fields_ids = @available_custom_fields.map(&:id)

    # filter values
    @selected = params[:sprint] || 'current'

    case @selected
      when 'all'
        sprint = nil
      when 'none'
        sprint = 'null'
      when 'current'
        sprint = 'current'
      else
        sprint = @selected
    end

    @user = params[:user] || 'all'
    if @user == 'all'
      user = nil
    elsif @user == 'unassigned'
      user = ""
    else
      user = @user
    end

    if params[:trackers] && params[:trackers] != 'null'
      @trackers = params[:trackers].split(',')
    else
      @trackers = @project.trackers.pluck(:name) & %w(Task Bug)
    end
    trackers_ids = @trackers.include?('All') ? nil : Tracker.where(name: @trackers).map(&:id)

    @plugin_path = File.join(Redmine::Utils.relative_url_root, 'plugin_assets', 'agile_dwarf')
    status_ids = []
    colcount = Setting.plugin_agile_dwarf['stcolumncount'].to_i
    for i in 1 .. colcount
      status_ids << Setting.plugin_agile_dwarf[('stcolumn' + i.to_s)].to_i
    end
    @statuses = {}
    IssueStatus.where(id: status_ids).each {|x| @statuses[x.id] = x.name}
    @columns = []
    for i in 0 .. colcount - 1
      tasks = SprintsTasks.get_tasks_by_status_and_tracker(@project, status_ids[i], trackers_ids, sprint, user)
      points = {}
      tasks.each do |task|
        # We process only int custom fields
        task.custom_field_values.each do |cfv|
          if cfv.custom_field.field_format == 'int' && (@available_custom_fields_ids.include? cfv.custom_field.id)
            value = cfv.value.to_i
            if value != 0
              custom_field = cfv.custom_field
              points[custom_field] ||= {}
              points[custom_field][task.assigned_to] ||= 0
              points[custom_field][task.assigned_to] += value
              points[custom_field][:sum] ||= 0
              points[custom_field][:sum] += value
            end
          end
        end
      end
      @columns << {:tasks => tasks, :id => status_ids[i], :points => points}
    end
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end

  def clear_flash
    flash.clear
  end
end
