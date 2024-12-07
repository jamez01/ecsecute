# Ecsecute

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/ecsecute`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

```bash
gem install ecsecute
```

## Usage

To use Ecsecute, you can run the following command to execute a command on an ECS task:

```sh
ecsecute exec -c <cluster_name> -t <task_id> -C <container_name> -i <command>
```

For example:

```sh
ecsecute exec -c my-cluster -t abcdef1234567890 -C my-container -i "ls -la"
```

Not all options are needed.  Each provided option can be a partial match.

e.g.

```sh
ecsecute exec -c web "ls -la"
```
ecsecute will help you search for the proper container and task.

Output:
```sh
Select cluster (Use ↑/↓ arrow keys, press Enter to select)
‣ staging-web
  production-web
Select task 
  qs7k8hudxifc60n1suvb0h6uhy3h04i0
‣ srgifyq315kyq3eh107kxp0h1xd0ajt4
Select container (Use ↑/↓ arrow keys, press Enter to select)
‣ staging-web
  staging-web-nginx-sidecar
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jamez01/ecsecute. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Copyright

Copyright (c) 2023 James Paterni. See [MIT License](LICENSE.txt) for further details.