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

    define(:find_all_workflow_events) do |id|
    end

    define(:get_workflow_tree) do |id|
    end

    define(:get_printable_workflow_tree) do |id|
    end

    define(:find_event_by_id) do |id|
    end

    define(:update_event_status) do |id, status|
    end

    define(:restart_event) do |id|
    end

    define(:reset_event) do |id|
    end

    define(:add_child_event) do |id, data|
    end

    define(:add_child_events) do |id, data|
    end
  end
end
