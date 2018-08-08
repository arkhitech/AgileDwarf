class AllSprintsController < ApplicationController
  unloadable

  def index
    @backlog = SprintsTasks.get_backlog.group_by(&:project_id).each {|project_id, sprint_tasks| sprint_tasks.sort!{|a,b| a.parent_id || 0 <=> b.parent_id || 0 } }
    
    @sprints = Sprints.all_sprints.select {|s| s.name.downcase.match(/release$/).nil? }
    @sprints.each {|s| s.tasks = SprintsTasks.get_tasks_by_sprint(nil, s.id) }
    @sprints = @sprints.group_by(&:project_id)

    @releases = Sprints.all_sprints.select {|s| s.name.downcase.match(/release$/).present? }
    @releases.each {|s| s.tasks = SprintsTasks.get_tasks_by_sprint(nil, s.id) }

    @plugin_path = File.join(Redmine::Utils.relative_url_root, 'plugin_assets', 'agile_dwarf')
    @closed_status = Setting.plugin_agile_dwarf["stclosed"].to_i
  end
end
