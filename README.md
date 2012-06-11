# Pawnee - making server provisioning easier

[NOTE: This is still a work in progress and not ready for use yet]

## Why

You may wonder why do we need another provisioning system, [here's](https://github.com/ryanstout/pawnee/blob/master/docs/FAQ.md) my answer.

## Goals

This system will:

1. **Setup recipes as gems**
  - Gems get prefixed so you can search for them
  - Gems inherit from main gem
2. **Gems recipes can be overridden in a rails folder**
	- either by a load path solution or monkeypatching
	  - they have a classname that can be predicted from the gem name
			- so anything that overrides that class can monkeypatch or replace parts of it
3. **It should use bundler**
  - so you just list the things you need on your server in a certain group (that only gets run on when installing)
  - you could use :path => '...'
  - the gems don't install the things in a bundle, just provide a task you can run to set them up
4. **It should run gems locally or remote**
	- based on the --servers option passed in
5. **It should integrate with capistrano**
	- we need a place to store server info....
		- redis somewhere?
		- Serverfile/Serverfile.lock
  - the servers and roles should be maintained by this system
  - but deploying should be a separate thing (not like rubber)
6. **It should use thor for template stuff**
	- and just overwrite it so files get copied to remote destinations if needed


A note on idempotence.  Being idempotent is a big selling point for chef.  Pawnee strives for idempotence but provides it in different ways.  For example, where chef would provide a more dsl like way to declare what to do when changes are made, pawnee tries to avoid too much DSL, so the recipe developer will need to be aware that the task may be run multiple times.  We find that either way the recipe developer needs to understand this situation, and with the Pawnee way, its made clearer in the code.

## Installation

Add any pawnee gem's you want to use to bundler:

    gem 'pawnee-nginx'

You can see currently available recipe gems [here](https://rubygems.org/search?utf8=%E2%9C%93&query=pawnee)

[Or you can create your own recipy gems](https://github.com/ryanstout/pawnee/blob/master/docs/GUIDE.md)

## Usage

### Config File

Setup a config/pawnee.yml file.  In this file you can specify any options you want to pass along with the servers:

Here's an example config with server's:

		servers:
		  - domain: server1.com
		    roles: [nginx, unicorn]
		  - domain: server2.com
		    roles: [unicorn]

Then run:

		bundle exec pawnee setup

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request




## Pawnee Provides Helpers For:

- files
- directories
- packages
- service calls (via invoking methods in other recipes)
- compile (untar/make/make install)
- users
- cron? [not complete]  (maybe leverage whenever gem)
- env [not complete]  (manage adding things to .base_profile somehow - maybe leverage insert_into_file stuff?)

## Standard Tasks

Pawnee defined some convention for task names so all gem's can provide standard ways to call things

	- #setup
	- #teardown
	- #restart
	- #stop
	- #start


## Options

In a task, recipes can access and change the self.options hash.  These values will be
passed from one task to another.  Gem tasks will be executed in the order they are defined
in bundler (at the moment, this may change)

## Configuration

standard config options:
- servers
- git_repo_url
- web_root
- aws...
- s3...

## exposed by unicorn for example
app_server_locations ['localhost:3000', 'localhost:3001'] - gets picked up on by nginx maybe?



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





### Roles
- gems define a roles they provide
	- [logically, this can only be one role right?]
	- multiple gems can provide the same role, but one gem can not provide multiple
- you say which roles you want to run (as --roles)
- servers say which roles they provide

1) list of gems that run the listed roles
2) run on each server that provides

