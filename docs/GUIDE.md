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

## Server Options

We'll come back to options in a minute, but quickly we have to talk about one special option, 'servers'.  'servers' should be setup as a default option on your setup and teardown tasks.

Servers can be a few things:

1. an array of domains (with an assumed default user of ubuntu)
2. an array of hashs like the following:
		[{'domain' => 'something.com', 'roles' => ['your gemname']}, ...]
3. a mix of either

These options can either be passed in on the command line like so:

		bundle exec pawnee yourgemname setup --servers something.com

Or they can be setup in the [config.yml file]().

## Actions

Since Pawnee is build on thor, we can use any of the thor actions