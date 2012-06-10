# Recipe Gem Creation Guide

## Overview

Pawnee tries to make it very easy to create recipes for setting up things on remote or local servers.  Pawnee provides a gem generator to get started, simply run:

		pawnee gem [gemname]

This will generate files for a gem in the current directory.  The word Recipe is used to refer to these pawnee gems (since it is a standard term in the provisioning world.)

## base.rb

The main code for your gem will go in lib/pawnee/[gemname]/base.rb  This file is a recipe class that inherits from Pawnee::Base.  

Pawnee uses the [thor gem](https://github.com/wycats/thor) to provide things like tasks and actions.  Pawnee::Base extends thor and adds in things to do the following:

1. allow actions to run remotely over ssh or locally.
2. allow tasks to run multiple times (once per server).
3. allow defaults in a config file for options
4. allow the options hash to be changed and passed between tasks

By adding these to thor, Pawnee::Base provides a great starting point for creating recipes.  It also tracks any class that inherits from it and adds it to a list of recipes so you can run:

		bundle exec pawnee setup
		
Running the above will automatically call setup on all pawnee recipes in the current Gemfile

## Tasks

Recipes have two default tasks, #setup and #teardown.  For most situations, think of #setup as "install" and #teardown as "uninstall".  To run setup now, in your gem directory you can do:

		bundle
		bundle exec pawnee [gemname] setup

Also, you could place the gem in another projects Gemfile (using the :path option for now) and then run something like:

		bundle exec pawnee setup

Again, this will invoke the setup task on all pawnee gems in the Gemfile.

Tasks can call other tasks using the #invoke method (see thor)

## Servers Option

We'll come back to options in a minute, but quickly we have to talk about one special option, 'servers'.  'servers' should be setup as a default option on your setup and teardown tasks.

Servers can be a few things:

1. an array of domains (with an assumed default user of ubuntu)
2. an array of hashs like the following:
		[{'domain' => 'something.com', 'roles' => ['your gemname']}, ...]
3. a mix of either

These options can either be passed in on the command line like so:

		bundle exec pawnee yourgemname setup --servers something.com

Or they can be setup in the [config.yml file](https://github.com/ryanstout/pawnee#config-file).

## Actions

### Thor Actions

Since Pawnee is build on thor, we can use any of the [thor actions](https://github.com/wycats/thor/wiki/Actions) inside our class.  Pawnee includes a gem called thor-ssh (which was written for pawnee) that extends thor and allows a .destination_connection to be set on any thor class.  .destination_connection is automatically setup for any task if the 'servers' option is set (again, either from the command line or in the config.yml file)  When destination_connection is set, any of the actions will use the local machine for the source, and the destination machine for the destination.

So running something like the following:

		copy_file('templates/test.txt', '/home/ubuntu/test.txt')

Would copy the file from templates/test.txt (in the gem) to /home/ubuntu/test.txt on the remote server (or servers if multiple servers were passed in)

**note**: in the current system, if multiple servers are passed in, the task is simply run once for each server.

thor-ssh also provides two methods for running any command:

 #run and #exec

 #run will log the command being run, #exec will not

### Pawnee Actions

Pawnee also provides its own set of actions for common server tasks.

install_package, remove_package, compile, create_user, delete_user

## Options

Pawnee also uses thor's option system.  This means your tasks should use thor's #desc and #method_option.  ([Read more here](https://github.com/wycats/thor/wiki/Getting-Started) and [here](https://github.com/wycats/thor/wiki/Method-Options))  This allows for an easily defined set of options for any task.  This also allows anyone to see what options the tasks take:

		bundle exec pawnee [yourgemname] help setup
		
^ would return a list of the options along with descriptions

By default pawnee makes it so any method options are scoped to the current gem.  However pawnee makes it easy for gems to share options.  Any gem can change the self.options hash and it will be passed (in its changed form) to the next task.  This means you could easily have one gem provide things like path to another gem.  (Just make sure the gem providing the paths is before the 2nd gem in the Gemfile).  When sharing options, some options make since to not be scoped to the gem.  In this case, you can run the #method_options inside of a global_options do block.

		global_options do
			method_option :deploy_path, :required => true
		end

This makes it easy to have the same option be used between gems.

	
