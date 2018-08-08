module AdtasksHelper
  def options_for_tracker_select
    options = @project.trackers.pluck(:name)
    options.unshift('All')
    options_for_select(options, @trackers)
  end
end
