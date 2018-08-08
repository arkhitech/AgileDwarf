class Sprints < Version
  unloadable

  attr_writer :tasks

  validate :start_and_end_dates

  scope :open_sprints, ->(project = nil) do
    scope = order('ir_start_date ASC, ir_end_date ASC')
    if project
      scope = scope.where("status = 'open' and (project_id IN (?) or sharing = 'system')", [project.id, project.parent_id].compact)
    else
      scope = scope.where("status = 'open'")
    end
    scope
  end

  scope :all_sprints, ->(project = nil) do
    scope = order('ir_start_date ASC, ir_end_date ASC')
    scope.where "project_id IN (?) OR sharing = 'system'", [project.id, project.parent_id].compact if project
    scope
  end

  def start_and_end_dates
    errors.add_to_base("Sprint cannot end before it starts") if self.ir_start_date && self.ir_end_date && self.ir_start_date >= self.ir_end_date
  end

  def tasks
    @tasks || SprintsTasks.get_tasks_by_sprint(self.project, self.id)
  end
end
