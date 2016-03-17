# Copyright (c) 2015, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# Neither the name of GROUPON nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "spec_helper"
require "backbeat/api"
require "backbeat/api/errors"
require "support/mock_http_client"

describe Backbeat::API do
  let(:client) { Backbeat::MockHttpClient.new }
  let(:api) { Backbeat::API.new(client) }

  context "workflows" do
    context "#create_workflow" do
      it "creates a workflow" do
        workflow_data = {
          name: "My Workflow",
          subject: "Subject",
          decider: "Decider"
        }

        expect(client).to receive(:post).with("/workflows", JSON.dump(workflow_data), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 201, body: JSON.dump({ id: 10 }) })

        workflow_id = api.create_workflow(workflow_data)[:id]

        expect(workflow_id).to eq(10)
      end

      it "returns a validation error if the workflow is invalid" do
        workflow_data = { name: "My Workflow", decider: "Decider" }

        expect(client).to receive(:post).with("/workflows", JSON.dump(workflow_data), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 422 })

        expect { api.create_workflow(workflow_data) }.to raise_error Backbeat::API::ValidationError
      end

      it "raises an authentication error if the request is not authenticated" do
        expect(client).to receive(:post).with("/workflows", JSON.dump({}), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 401, body: JSON.dump({ error: "Unauthorized" }) })

        expect { api.create_workflow({}) }.to raise_error Backbeat::API::AuthenticationError, { error: "Unauthorized" }.to_s
      end
    end

    context "#find_workflow_by_id" do
      it "finds a workflow by id" do
        workflow_data = {
          id: 5,
          workflowId: 5,
          parentId: nil,
          name: "My Workflow",
          subject: "Subject",
          decider: "Decider",
          userId: "123"
        }

        expect(client).to receive(:get).with("/workflows/5", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: JSON.dump(workflow_data) })

        workflow = api.find_workflow_by_id(5)

        expect(workflow).to eq(Backbeat::Packer.underscore_keys(workflow_data))
      end

      it "raises a not found error if the workflow is not found" do
        expect(client).to receive(:get).with("/workflows/5", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 404, body: JSON.dump({ error: "Record not found" })})

        expect { api.find_workflow_by_id(5) }.to raise_error Backbeat::API::NotFoundError, { error: "Record not found" }.to_s
      end
    end

    context "#find_workflow_by_subject" do
      let(:workflow_query) {{
        name: "My Workflow",
        subject: "Subject",
        decider: "Decider"
      }}

      let(:workflow_data) {
        workflow_query.merge(
          id: 5,
          workflowId: 5,
          parentId: nil,
          userId: "123"
        )
      }

      it "finds a workflow by subject" do
        expect(client).to receive(:get).with("/workflows", {
          headers: { "Accept" => "application/json"},
          query: workflow_query
        }).and_return({ status: 200, body: JSON.dump(workflow_data) })

        workflow = api.find_workflow_by_subject(workflow_query)

        expect(workflow).to eq(Backbeat::Packer.underscore_keys(workflow_data))
      end

      it "returns false if the workflow is not found" do
        expect(client).to receive(:get).with("/workflows", {
          headers: { "Accept" => "application/json"},
          query: workflow_query
        }).and_return({ status: 404 })

        expect(api.find_workflow_by_subject(workflow_query)).to eq(false)
      end
    end

    context "#signal_workflow" do
      let(:signal_data) {{ client_data: { arguments: [1, 2, 3] }}}

      it "signals the workflow with the id, name, and client data" do
        expect(client).to receive(:post).with("/workflows/10/signal", JSON.dump(signal_data), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 201, body: { id: 11 }.to_json })

        response = api.signal_workflow(10, :my_signal, signal_data)

        expect(response).to eq(11)
      end

      it "raises a validation error if the signal data is not valid" do
        expect(client).to receive(:post).with("/workflows/10/signal", JSON.dump(signal_data), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 422, body: JSON.dump({ error: "Invalid" })})

        expect { api.signal_workflow(10, :my_signal, signal_data) }.to raise_error Backbeat::API::ValidationError, { error: "Invalid" }.to_s
      end
    end

    context "#complete_workflow" do
      it "makes a request to mark the workflow complete" do
        expect(client).to receive(:put).with("/workflows/20/complete", JSON.dump({}), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 200 })

        api.complete_workflow(20)
      end
    end

    context "#find_all_workflow_children" do
      it "gets the workflow children" do
        child_data = [{
          id: 5,
          workflowId: 5,
          parentId: nil,
          name: "My Activity",
          subject: "Subject",
          decider: "Decider",
          userId: "123"
        }]

        expect(client).to receive(:get).with("/workflows/5/children", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: JSON.dump(child_data) })

        children = api.find_all_workflow_children(5)

        expect(children).to eq(Backbeat::Packer.underscore_keys(child_data))
      end
    end

    context "#find_all_workflow_activities" do
      it "gets the workflow activity history" do
        activity_data = [{
          id: 5,
          workflow_id: 5,
          parentId: nil,
          name: "My Activity",
          subject: "Subject",
          decider: "Decider",
          userId: "123"
        }]

        expect(client).to receive(:get).with("/workflows/3/nodes", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: JSON.dump(activity_data) })

       activities = api.find_all_workflow_activities(3)

        expect(activities).to eq(Backbeat::Packer.underscore_keys(activity_data))
      end
    end

    context "#get_tree" do
      it "gets the hash representation of the workflow tree" do
        tree_data = { id: 5, children: [] }

        expect(client).to receive(:get).with("/workflows/3/tree", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: JSON.dump(tree_data) })

        tree = api.get_workflow_tree(3)

        expect(tree).to eq(tree_data)
      end
    end

    context "#get_printable_tree" do
      it "gets the printable representation of the workflow tree" do
        tree_data = { print: "ID NAME \n\n ID Name etc" }

        expect(client).to receive(:get).with("/workflows/3/tree/print", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: JSON.dump(tree_data) })

        tree = api.get_printable_workflow_tree(3)

        expect(tree).to eq(tree_data)
      end
    end
  end

  context "activities" do
    let(:activity_data) {{
      id: 5,
      workflow_id: 5,
      parent_id: nil,
      mode: "blocking",
      client_data: {},
      metadata: {},
      name: "My Workflow",
      subject: "Subject",
      decider: "Decider",
      user_id: "123"
    }}

    context "#find_activity_by_id" do
      it "finds an activity by id" do
        expect(client).to receive(:get).with("/activities/25", {
          headers: { "Accept" => "application/json"}
        }).and_return({ status: 200, body: JSON.dump(activity_data) })

        activity = api.find_activity_by_id(25)

        expect(activity).to eq(activity_data)
      end
    end

    context "#update_activity_status" do
      it "sends a request to update the activity status" do
        expect(client).to receive(:put).with("/activities/25/status/errored", JSON.dump({ response: nil }), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 200 })

        api.update_activity_status(25, :errored)
      end

      it "sends a result" do
        expect(client).to receive(:put).with("/activities/10/status/completed", JSON.dump({ response: { result: 5, error: nil }}), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 200 })

        api.update_activity_status(10, :completed, { result: 5, error: nil })
      end

      it "raises a status change error" do
        expect(client).to receive(:put).with("/activities/10/status/processing", JSON.dump({ response: nil }), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 409 })

        expect { api.update_activity_status(10, :processing) }.to raise_error(Backbeat::API::InvalidStatusChangeError)
      end
    end

    context "#restart_activity" do
      it "sends a request to restart the activity" do
        expect(client).to receive(:put).with("/activities/25/restart", JSON.dump({}), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 200 })

        api.restart_activity(25)
      end
    end

    context "#reset_activity" do
      it "sends a request to reset the node" do
        expect(client).to receive(:put).with("/activities/30/reset", JSON.dump({}), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 200 })

        api.reset_activity(30)
      end
    end

    context "#add_child_activities" do
      it "creates new child activities on the activity" do
        expect(client).to receive(:post).with("/activities/12/decisions", JSON.dump({ decisions: [activity_data] }), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 201 })

        api.add_child_activities(12, [activity_data])
      end
    end

    context "#add_child_activity" do
      it "creates a new child activity on the activity" do
        expect(client).to receive(:post).with("/activities/12/decisions", JSON.dump({ decisions: [activity_data] }), {
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        }).and_return({ status: 201, body: [13].to_json })

        expect(api.add_child_activity(12, activity_data)).to eq(13)
      end
    end

    context "#search_activities" do
      it "searches activities by the provided params" do
        expect(client).to receive(:get).with("/activities/search", {
          headers: {
            "Accept" => "application/json"
          },
          query: { current_status: :errored }
        }).and_return({ status: 200, body: [{ id: 10 }].to_json })

        expect(api.search_activities({ current_status: :errored })).to eq([{ id: 10 }])
      end
    end
  end
end
