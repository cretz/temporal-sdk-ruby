require 'temporal/api/common/v1/message_pb'
require 'temporal/api/failure/v1/message_pb'
require 'temporal/activity'
require 'temporal/data_converter'
require 'temporal/sdk/core/activity_task/activity_task_pb'
require 'temporal/worker/activity_runner'
require 'temporal/worker/sync_worker'

class TestRunnableActivity < Temporal::Activity
  def execute(command)
    case command
    when 'foo'
      'bar'
    when 'fail'
      raise StandardError, 'Test failure'
    when 'heartbeat'
      activity.heartbeat('test')
    end
  end
end

describe Temporal::Worker::ActivityRunner do
  subject { described_class.new(TestRunnableActivity, task, task_queue, token, worker, converter) }

  let(:task) do
    Coresdk::ActivityTask::Start.new(
      workflow_namespace: 'test-namespace',
      workflow_type: 'test-workflow',
      workflow_execution: { workflow_id: 'test-workflow-id', run_id: 'test-run-id' },
      activity_id: '42',
      activity_type: 'TestRunnableActivity',
      header_fields: converter.to_payload_map('foo' => 'bar'),
      input: [converter.to_payload(command)],
      heartbeat_details: [converter.to_payload('heartbeat')],
      scheduled_time: Google::Protobuf::Timestamp.from_time(time),
      current_attempt_scheduled_time: Google::Protobuf::Timestamp.from_time(time),
      started_time: Google::Protobuf::Timestamp.from_time(time),
      attempt: 2,
      schedule_to_close_timeout: Google::Protobuf::Duration.new(seconds: 42, nanos: 999_000_000),
      start_to_close_timeout: Google::Protobuf::Duration.new(seconds: 42, nanos: 999_000_000),
      heartbeat_timeout: Google::Protobuf::Duration.new(seconds: 42, nanos: 999_000_000),
      is_local: false,
    )
  end
  let(:time) { Time.now }
  let(:task_queue) { 'test-task-queue' }
  let(:token) { 'test_token' }
  let(:worker) { instance_double(Temporal::Worker::SyncWorker) }
  let(:converter) { Temporal::DataConverter.new }

  describe '#run' do
    let(:command) { 'foo' }

    it 'returns a payload with activity result' do
      result = subject.run

      expect(result).to be_an_instance_of(Temporal::Api::Common::V1::Payload)
      expect(result.data).to eq('"bar"')
    end

    it 'initialized context with activity info' do
      allow(Temporal::Activity::Context).to receive(:new).and_call_original

      subject.run

      expect(Temporal::Activity::Context).to have_received(:new) do |info|
        expect(info).to be_an_instance_of(Temporal::Activity::Info)
        expect(info.activity_id).to eq('42')
        expect(info.activity_type).to eq('TestRunnableActivity')
        expect(info.attempt).to eq(2)
        expect(info.current_attempt_scheduled_time).to eq(time)
        expect(info.heartbeat_details).to eq(['heartbeat'])
        expect(info.heartbeat_timeout).to eq(42.999)
        expect(info).to be_local
        expect(info.schedule_to_close_timeout).to eq(42.999)
        expect(info.scheduled_time).to eq(time)
        expect(info.start_to_close_timeout).to eq(42.999)
        expect(info.started_time).to eq(time)
        expect(info.task_queue).to eq(task_queue)
        expect(info.task_token).to eq(token)
        expect(info.workflow_id).to eq('test-workflow-id')
        expect(info.workflow_namespace).to eq('test-namespace')
        expect(info.workflow_run_id).to eq('test-run-id')
        expect(info.workflow_type).to eq('test-workflow')
      end
    end

    context 'heartbeat' do
      let(:command) { 'heartbeat' }

      before do
        allow(worker).to receive(:record_activity_heartbeat).and_return(nil)
      end

      it 'supplies a heartbeat proc for the context' do
        subject.run

        expect(worker).to have_received(:record_activity_heartbeat) do |task_token, payloads|
          expect(task_token).to eq(token)
          expect(payloads.length).to eq(1)
          expect(payloads.first.data).to eq('"test"')
        end
      end
    end

    context 'when activity raises' do
      let(:command) { 'fail' }

      it 'returns a failure' do
        result = subject.run

        expect(result).to be_an_instance_of(Temporal::Api::Failure::V1::Failure)
        expect(result.message).to eq('Test failure')
      end
    end
  end
end