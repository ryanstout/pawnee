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