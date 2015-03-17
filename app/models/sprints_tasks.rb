class SprintsTasks < Issue
  unloadable

  acts_as_list :column => "ir_position"

  ORDER = 'case when issues.ir_position is null then 1 else 0 end ASC, case when issues.ir_position is NULL then issues.id else issues.ir_position end ASC'

  def self.get_tasks_by_status_and_tracker(project, status, tracker_id, sprint, user)
    cond = ['issues.project_id = ? and status_id = ?', project.id, status]

    if sprint == 'null'
      cond[0] += ' and fixed_version_id is null'
    elsif sprint == 'current'
      cond[0] += ' and fixed_version_id = ?'
      cond << Sprints.open_sprints(project).first.id
    elsif sprint
      cond[0] += ' and fixed_version_id = ?'
      cond << sprint
    end

    if user == '' # Unassigned
      cond[0] += ' and assigned_to_id IS ?'
      cond << nil
    elsif user # Assigned to user
      cond[0] += ' and assigned_to_id = ?'
      user = User.current.id if user == 'current'
      cond << user
    end

    if tracker_id
      if tracker_id.kind_of? Enumerable
        trackers = tracker_id.join(',')
      else
        trackers = tracker_id
      end
      cond[0] += " and tracker_id IN (#{trackers})"
    end

    tasks = SprintsTasks.select('issues.*, sum(hours) as spent').order(SprintsTasks::ORDER).where(*cond).group('issues.id').joins(:status).joins('LEFT JOIN time_entries ON time_entries.issue_id = issues.id').includes(:assigned_to)

    filter_out_user_stories_with_children tasks
  end

  def self.get_tasks_by_sprint(project, sprint)
    cond = ['is_closed = ?', false]
    if project.present?
      cond[0] += ' and project_id IN (?)'
      cond << [project.id, project.parent_id].compact
    end

    if sprint.present?
      if sprint == 'null'
        cond[0] += ' and fixed_version_id is null'
      else
        cond[0] += ' and fixed_version_id = ?'
        cond << sprint
      end
    end

    tasks = SprintsTasks.select('issues.*, trackers.name AS t_name').order(SprintsTasks::ORDER).where(cond).joins(:status).joins('LEFT JOIN issue_statuses on issue_statuses.id = status_id left join trackers on trackers.id = tracker_id').includes(:assigned_to)

    filter_out_user_stories_with_children tasks
  end

  def self.get_tasks_by_sprint_and_tracker(project, sprint, tracker_id)
    cond = ['is_closed = ?', false]
    if project.present?
      cond[0] += ' and project_id IN (?)'
      cond << [project.id, project.parent_id].compact
    end

    if tracker_id
      if tracker_id.kind_of? Enumerable
        trackers = tracker_id.join(',')
      else
        trackers = tracker_id
      end
      cond[0] += " and tracker_id IN (#{trackers})"
    end

    if sprint.present?
      if sprint == 'null'
        cond[0] += ' and fixed_version_id is null'
      else
        cond[0] += ' and fixed_version_id = ?'
        cond << sprint
      end
    end

    tasks = SprintsTasks.select('issues.*, trackers.name AS t_name').order(SprintsTasks::ORDER).conditions(cond).joins(:status).joins('left join issue_statuses on issue_statuses.id = status_id left join trackers on trackers.id = tracker_id').includes(:assigned_to)

    filter_out_user_stories_with_children tasks
  end

  def self.filter_out_user_stories_with_children(tasks)
    # if the task is a user story then only display it if it has no child issues.
    # if it does then we schedule the child issues, not the user story itself
    if user_story_tracker_id = Tracker.where(name: 'UserStory').first.try(:id)
      tasks.select do |t|
        if t.tracker_id == user_story_tracker_id
          t.descendants.empty?
        else
          true
        end
      end
    else
      tasks
    end
  end

  def self.get_backlog(project = nil, tracker_id = nil)
    SprintsTasks.get_tasks_by_sprint_and_tracker(project, 'null', tracker_id)
  end

  def move_after(prev_id)
    remove_from_list

    if prev_id.to_s == ''
      prev = nil
    else
      prev = SprintsTasks.find(prev_id)
    end

    if prev.blank?
      insert_at
      move_to_top
    elsif !prev.in_list?
      insert_at
      move_to_bottom
    else
      insert_at(prev.ir_position + 1)
    end
  end

  def blocked?
    @is_blocked ||= custom_field_values.find { |cfv| cfv.custom_field_id.to_s == Setting.plugin_agile_dwarf['block_custom_field_id'].to_s }.try(:value) == '1'
  end

  def update_and_position!(params)
    attribs = params.select{|k,v| k != 'id' && k != 'project_id' && SprintsTasks.column_names.include?(k) }
    attribs = Hash[*attribs.flatten]
    if params[:prev]
      move_after(params[:prev])
    end
    self.init_journal(User.current)
    update_attributes! attribs
  end

  def self.available_custom_fields(project)
    if Setting.plugin_agile_dwarf[:custom_fields_ids]
      enabled_custom_fields_ids = Setting.plugin_agile_dwarf[:custom_fields_ids].map(&:to_i)
      project.all_issue_custom_fields.select { |cf| enabled_custom_fields_ids.include? cf.id }
    else
      []
    end
  end

  # When user clicks on "new task" the task is created and further fields
  # changes just updates the existing task so we can't have any mandatory
  # custom fields without default values.
  def available_custom_fields
    super().delete_if { |cf| cf.is_required && !cf.default_value }
  end

  private

    attr_reader :is_blocked
end
