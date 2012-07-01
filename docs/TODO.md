TODO: Provide testing stubs for gems
TODO: Add a as_user('user') do .. end option
				- needs to look to options for how to get to root
				- have it run all commands as that user (for sftp actions we'll set the own after)
				- we'll need to change exec and run to work from within a shell session
					- maybe have an option to run from within a shell, or we could get them into the right place every time
				- maybe we should add a system to "get you to root, then get you to another user"
TODO: Need to make a clear way for pawnee gems (and recipes) to provide actions (example, git gem provides git actions)
TODO: Test to make sure arguments work directly as well (they probably don't right now)
TODO: Make it so copied files can be overridden in a rails project
TODO: Track modified on compile?
TODO: Should setup self.source_root to point to the templates dir in the gem
TODO: Add --verbose option that shows the output of any outputs (bundler for example)
 				- maybe show stderr by default?
				- maybe option to show on run/exec
				- show stderr when there's a non-0 exit status
TODO: Make sure it would print out any errors from bundler
TODO: Raise error on run error (with options to ignore during run, or options to always ignore (global config))
TODO: Allow ssh host strings user:pw@domain
TODO: Make thor-ssh local api compatible
TODO: Move to self namespacing - remove global_options
TODO: Work out dependency loading
TODO: Make the source_root work by default



THINK ABOUT:

---- logging system -----

Log levels
- error - stderr
- info - actions
- debug - stdout

State Changes (and colors):
- create (green)
- update (yellow)
- destroy (red?)
- identical (blue)

Log Actions
same, identical, update, add, run


def setup
	install_package('build-essential')
	
	modify_block do
		install_package('nginx')

		if modified?
			invoke Pawnee::Nginx::Base restart
		end
	end
end