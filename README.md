# Pawnee - making server provisioning easier

[NOTE: This is still a work in progress and not ready for use yet]

This system will:

1) Setup recipes as gems
  - Gems get prefixed so you can search for them
	- Gems inherit from main gem
2) Gems recipes can be overridden in a rails folder
	- either by a load path solution or monkeypatching
	  - they have a classname that can be predicted from the gem name
			- so anything that overrides that class can monkeypatch or replace parts of it
3) It should use bundler
  - so you just list the things you need on your server in a certain group (that only gets run on when installing)
  - you could use :path => '...'
  - the gems don't install the things in a bundle, just provide a task you can run to set them up
4) It should run gems locally or remote
	- based on the --servers option passed in
5) It should integrate with capistrano
	- we need a place to store server info....
		- redis somewhere?
		- Serverfile/Serverfile.lock
  - the servers and roles should be maintained by this system
  - but deploying should be a separate thing (not like rubber)
6) It should use thor for template stuff
	- and just overwrite it so files get copied to remote destinations if needed


Problems with Chef/Puppet
-------------------------

1) Little to no testing of recipes (at least for Chef)
2) Complicated recipe upgrading/code reuse patterns
3) You need to run the code locally (should be over ssh)

[chef's providers as an example: http://wiki.opscode.com/display/chef/Resources]
Helpers
- file [done]
- directory [done]
- package [done]
- service (restart maybe?)
- compile: tar/make/make install [done]
- user
- gem install
- cron? (maybe leverage whenever gem)
- env (manage adding things to .base_profile somehow - maybe leverage insert_into_file stuff?)

## Standard Tasks
	- #restart
	- #stop
	- #start


### Options
In a task, recipes can access and change the self.options hash.  These values will be
passed from one task to another.

### Configuration

standard config options:
servers
git_repo_url
web_root
aws...
s3...

# exposed by unicorn for example
app_server_locations ['localhost:3000', 'localhost:3001'] - gets picked up on by nginx maybe?


TODO: Provide testing stubs for gems
TODO: Add a as_user('user') do .. end option
				- needs to look to options for how to get to root
				- have it run all commands as that user (for sftp actions we'll set the own after)
				- we'll need to change exec and run to work from within a shell session
					- maybe have an option to run from within a shell, or we could get them into the right place every time
				- maybe we should add a system to "get you to root, then get you to another user"
TODO: Need to make a clear way for pawnee gems (and recipes) to provide actions (example, git gem provides git actions)
TODO: Run actions in threads (across multiple servers)
TODO: Test to make sure arguments work directly as well (they probably don't right now)




### ThorSsh Extensions to Thor
We make a few modifications to allow it to be used as the base to pawnee
1) We make it so all actions can be run either locally or remotely via ssh through the thor-ssh gem
2) We make options mutable and use that to allow the passing around of options




server connection system
  - fog
  - looks at fog api and tags to figure out what servers are running and their roles

core gem
  - provides dsl features for setting stuff up
    - packages ['...', '...']  # uses apt
    - file copy in with erb
  - all DSL commands can be run either locally or remote
    - so file copy uploads if needed
  - provides setup for defaults
    - ec2/s3 credentials
    - deploy_path(/mnt/[name])
  - provides generator for building new gems

deployment:
  - include in deploy.rb to setup servers and roles
  - standard cap deploy











## Installation

Add this line to your application's Gemfile:

    gem 'pawnee'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pawnee

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request




### Roles
- gems define a roles they provide
	- [logically, this can only be one role right?]
	- multiple gems can provide the same role, but one gem can not provide multiple
- you say which roles you want to run (as --roles)
- servers say which roles they provide

1) list of gems that run the listed roles
2) run on each server that provides

