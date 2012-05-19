# Gets the parameters for logging into the vagrant server

require 'vagrant'

@vm = Vagrant::Environment.new
pk_path = @vm.config.ssh.private_key_path || @vm.env.default_private_key_path
keys = [File.expand_path(pk_path, @vm.env.root_path)]

host      = env.primary_vm.config.ssh.host
port      = env.primary_vm.config.ssh.port
username  = env.primary_vm.config.ssh.username

