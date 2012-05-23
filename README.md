# Pawnee

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
4) It should run gems locally or remote (based on a config somehow)
5) It should integrate with capistrano
	- we need a place to store server info....
		- redis somewhere?
		- Serverfile/Serverfile.lock
  - the servers and roles should be maintained by this system
  - but deploying should be a separate thing (not like rubber)
6) It should use thor for template stuff
	- and just overwrite it so files get copied to remote destinations if needed
	
	
	
TODO: Something like:

in_group('group') do
	in_user('user') do
		...
	end
end

TODO: Need to make a clear way for pawnee gems (and recipes) to provide actions (example, git gem provides git actions)


RECIPE:
#setup(destination_server='something.com')


Problems with Chef/Puppet
-------------------------

1) Little to no testing of recipes (at least for Chef)
2) Complicated recipe upgrading/code reuse patterns
3) You need to run the code locally (should be over ssh)

[chef's providers as an example: http://wiki.opscode.com/display/chef/Resources]
Helpers
- user
- file [done]
- directory [done]
- package [done]
- service (restart maybe?)
- compile: tar/make/make install [done]
- gem install
- cron? (maybe leverage whenever)
- env (manage adding things to .base_profile somehow - maybe leverage insert_into_file stuff?)


Some standards:

#restart - should restart the service






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
