require "surrogate"

module Backbeat
  class MockApi
    Surrogate.endow self

    define(:create_workflow) do |data|
    end

    define(:create_workflow) do |data|
    end

    define(:find_workflow_by_id) do |id|
    end

    define(:find_workflow_by_subject) do |data|
    end

    define(:signal_workflow) do |id, name, data|
    end

    define(:complete_workflow) do |id|
    end

    define(:find_all_workflow_children) do |id|
    end

    define(:find_all_workflow_activities) do |id|
    end

    define(:get_workflow_tree) do |id|
    end

    define(:get_printable_workflow_tree) do |id|
    end

    define(:find_activity_by_id) do |id|
    end

    define(:update_activity_status) do |id, status, result = nil|
    end

    define(:restart_activity) do |id|
    end

    define(:reset_activity) do |id|
    end

    define(:add_child_activity) do |id, data|
    end

    define(:add_child_activities) do |id, data|
    end
  end
end
