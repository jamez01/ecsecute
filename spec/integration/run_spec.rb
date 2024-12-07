require 'ecsecute/cli'

RSpec.describe Ecsecute::CLI do
  describe '#version' do
    it 'prints the version' do
      cli = Ecsecute::CLI.new
      expect { cli.version }.to output("v#{Ecsecute::VERSION}\n").to_stdout
    end
  end

  describe '#exec' do
    it 'invokes the exec command' do
      cli = Ecsecute::CLI.new
      allow(cli).to receive(:options).and_return({})
      allow(Ecsecute::Commands::Exec).to receive(:new).and_return(double(execute: true))

      expect(Ecsecute::Commands::Exec).to receive(:new).with(true, {})
      cli.exec
    end
  end
end