require "spec_helper"
require "backbeat/api"
require "backbeat/api/errors"
require "backbeat/mock_http_client"

describe Backbeat::Api do
  let(:client) { MockHttpClient.new }
  let(:api) { Backbeat::Api.new(client) }

  context "workflows" do
    context "create_workflow" do
      it "creates a workflow" do
        workflow_data = {
          name: "My Workflow",
          subject: "Subject",
          decider: "Decider"
        }

        expect(client).to receive(:post).with("/v2/workflows", MultiJson.dump(workflow_data), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 201, body: "10" })

        workflow_id = api.create_workflow(workflow_data)

        expect(workflow_id).to eq(10)
      end

      it "returns a validation error if the workflow is invalid" do
        workflow_data = { name: "My Workflow", decider: "Decider" }

        expect(client).to receive(:post).with("/v2/workflows", MultiJson.dump(workflow_data), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 422 })

        expect { api.create_workflow(workflow_data) }.to raise_error Backbeat::Api::ValidationError
      end
    end

    context "find_workflow_by_id" do
      it "finds a workflow by id" do
        workflow_data = {
          id: 5,
          workflow_id: 5,
          parent_id: nil,
          name: "My Workflow",
          subject: "Subject",
          decider: "Decider",
          user_id: "123"
        }

        expect(client).to receive(:get).with("/v2/workflows/5", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: MultiJson.dump(workflow_data) })

        workflow = api.find_workflow_by_id(5)

        expect(workflow).to eq(workflow_data)
      end

      it "raises a not found error if the workflow is not found" do
        expect(client).to receive(:get).with("/v2/workflows/5", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 404 })

        expect { api.find_workflow_by_id(5) }.to raise_error Backbeat::Api::NotFoundError
      end
    end

    context "find_workflow_by_subject" do
      let(:workflow_query) {{
        name: "My Workflow",
        subject: "Subject",
        decider: "Decider"
      }}

      let(:workflow_data) {
        workflow_query.merge(
          id: 5,
          workflow_id: 5,
          parent_id: nil,
          user_id: "123"
        )
      }

      it "finds a workflow by subject" do
        expect(client).to receive(:get).with("/v2/workflows", {
          headers: { "Accept" => "application/json"},
          query: workflow_query
        }).and_return({ status: 200, body: MultiJson.dump(workflow_data) })

        workflow = api.find_workflow_by_subject(workflow_query)

        expect(workflow).to eq(workflow_data)
      end

      it "raises a not found error if the workflow is not found" do
        expect(client).to receive(:get).with("/v2/workflows", {
          headers: { "Accept" => "application/json"},
          query: workflow_query
        }).and_return({ status: 404 })

        expect { api.find_workflow_by_subject(workflow_query) }.to raise_error Backbeat::Api::NotFoundError
      end
    end

    context "signal_workflow" do
      let(:signal_data) {{ client_data: { arguments: [1, 2, 3] }}}

      it "signals the workflow with the id, name, and client data" do
        expect(client).to receive(:post).with("/v2/workflows/10/signal/my_signal", MultiJson.dump(signal_data), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 201, body: "11" })

        response = api.signal_workflow(10, :my_signal, signal_data)

        expect(response).to eq(11)
      end

      it "raises a validation error if the signal data is not valid" do
        expect(client).to receive(:post).with("/v2/workflows/10/signal/my_signal", MultiJson.dump(signal_data), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 422 })

        expect { api.signal_workflow(10, :my_signal, signal_data) }.to raise_error Backbeat::Api::ValidationError
      end
    end

    context "complete_workflow" do
      it "makes a request to mark the workflow complete" do
        expect(client).to receive(:put).with("/v2/workflows/20/complete", MultiJson.dump({}), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 200 })

        api.complete_workflow(20)
      end
    end

    context "find_all_workflow_children" do
      it "gets the workflow children" do
        child_data = [{
          id: 5,
          workflow_id: 5,
          parent_id: nil,
          name: "My Activity",
          subject: "Subject",
          decider: "Decider",
          user_id: "123"
        }]

        expect(client).to receive(:get).with("/v2/workflows/5/children", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: MultiJson.dump(child_data) })

        children = api.find_all_workflow_children(5)

        expect(children).to eq(child_data)
      end
    end

    context "find_all_workflow_events" do
      it "gets the workflow event history" do
        event_data = [{
          id: 5,
          workflow_id: 5,
          parent_id: nil,
          name: "My Activity",
          subject: "Subject",
          decider: "Decider",
          user_id: "123"
        }]

        expect(client).to receive(:get).with("/v2/workflows/3/events", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: MultiJson.dump(event_data) })

        events = api.find_all_workflow_events(3)

        expect(events).to eq(event_data)
      end
    end

    context "get_tree" do
      it "gets the hash representation of the workflow tree" do
        tree_data = { id: 5, children: [] }

        expect(client).to receive(:get).with("/v2/workflows/3/tree", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: MultiJson.dump(tree_data) })

        tree = api.get_workflow_tree(3)

        expect(tree).to eq(tree_data)
      end
    end

    context "get_printable_tree" do
      it "gets the printable representation of the workflow tree" do
        tree_data = { print: "ID NAME \n\n ID Name etc" }

        expect(client).to receive(:get).with("/v2/workflows/3/tree/print", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: MultiJson.dump(tree_data) })

        tree = api.get_printable_workflow_tree(3)

        expect(tree).to eq(tree_data)
      end
    end
  end
end
