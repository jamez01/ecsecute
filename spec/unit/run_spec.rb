require 'ecsecute/commands/run'

RSpec.describe Ecsecute::Commands::Run do
  it "executes `run` command successfully" do
    output = StringIO.new
    I = nil
    options = {}
    command = Ecsecute::Commands::Run.new(I, options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
