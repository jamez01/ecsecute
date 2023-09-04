RSpec.describe "`ecsecute run` command", type: :cli do
  it "executes `ecsecute help run` command successfully" do
    output = `ecsecute help run`
    expected_output = <<-OUT
Usage:
  ecsecute run I

Options:
  -h, [--help], [--no-help]  # Display usage information

Run command on a ecs task
    OUT

    expect(output).to eq(expected_output)
  end
end
