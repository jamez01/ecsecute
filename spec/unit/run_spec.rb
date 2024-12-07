require 'ecsecute/commands/exec'
require 'aws-sdk-ecs'

RSpec.describe Ecsecute::Commands::Exec do
  let(:options) { { 'region' => 'us-east-1', 'interactive' => true } }
  let(:command) { 'ls' }
  let(:exec_command) { Ecsecute::Commands::Exec.new(command, options) }

  describe '#initialize' do
    it 'sets the region' do
      expect(exec_command.region).to eq('us-east-1')
    end
  end

  describe '#interactive' do
    it 'returns --interactive when interactive is true' do
      expect(exec_command.interactive).to eq('--interactive')
    end

    it 'returns an empty string when interactive is false' do
      exec_command.instance_variable_set(:@interactive, false)
      expect(exec_command.interactive).to eq('')
    end
  end

  describe '#tasks' do
    it 'returns a list of tasks' do
      allow(exec_command).to receive(:cluster).and_return('default')
      allow(exec_command.instance_variable_get(:@client)).to receive(:list_tasks).and_return(double(task_arns: ['arn:aws:ecs:us-east-1:123456789012:task/default/abcdef1234567890']))
      expect(exec_command.tasks).to eq(['abcdef1234567890'])
    end
  end

  describe '#execute' do
    it 'executes the command' do
      allow(exec_command).to receive(:validate!)
      allow(exec_command).to receive(:cluster).and_return('default')
      allow(exec_command).to receive(:task).and_return('abcdef1234567890')
      allow(exec_command).to receive(:container).and_return('my-container')
      allow(exec_command).to receive(:interactive).and_return('--interactive')

      expect(Kernel).to receive(:exec).with("aws ecs execute-command  --region us-east-1 --cluster default --task abcdef1234567890  --container my-container --command ls --interactive")
      exec_command.execute
    end
  end
end