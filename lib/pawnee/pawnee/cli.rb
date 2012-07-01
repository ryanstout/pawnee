require 'pawnee/base'
require 'thor'
require 'thor-ssh'

# thor/group does not get correctly included in thor
require 'thor/group'

module Pawnee
  class CLI < Pawnee::Base    
    # Set blank namespace
    namespace ''

    desc "setup", "calls setup for each pawnee gem in bundler"
    method_option :roles, :type => :array, :default => :all
    def setup
      Pawnee::Base.invoke_roles(:setup, self.options[:roles], self.options)
    end


    desc "teardown", "calls teardown for each pawnee gem in bundler"
    method_option :roles, :type => :array, :default => :all
    def teardown
      Pawnee::Base.invoke_roles(:setup, self.options[:roles], self.options)
    end

    # Create a new gem (pulled from bundler and modified - MIT LICENSE)
    desc "gem GEM", "Creates a skeleton recipie"
    method_option :bin, :type => :boolean, :default => false, :aliases => '-b', :banner => "Generate a binary for your library."
    def gem(name)
      # Prefix all gems with pawnee-
      dir_name = 'pawnee-' + name.chomp("/") # remove trailing slash if present
      folder_name = "pawnee/" + name
      target = File.join(Dir.pwd, dir_name)
      constant_name = "Pawnee::" + name.split('-').map{|q| q[0..0].upcase + q[1..-1] }.join('')
      puts constant_name
      constant_array = constant_name.split('::')
      puts constant_array.inspect
      git_user_name = `git config user.name`.chomp
      git_user_email = `git config user.email`.chomp
      opts = {
        # Don't require the pawnee- when requring though
        :name           => name,
        :constant_name  => constant_name,
        :constant_array => constant_array,
        :author         => git_user_name.empty? ? "TODO: Write your name" : git_user_name,
        :email          => git_user_email.empty? ? "TODO: Write your email address" : git_user_email
      }
      template(File.join("newgem/Gemfile.tt"),               File.join(target, "Gemfile"),                opts)
      template(File.join("newgem/Rakefile.tt"),              File.join(target, "Rakefile"),               opts)
      template(File.join("newgem/LICENSE.tt"),               File.join(target, "LICENSE"),                opts)
      template(File.join("newgem/README.md.tt"),             File.join(target, "README.md"),              opts)
      template(File.join("newgem/gitignore.tt"),             File.join(target, ".gitignore"),             opts)
      template(File.join("newgem/newgem.gemspec.tt"),        File.join(target, "#{dir_name}.gemspec"),        opts)
      template(File.join("newgem/lib/newgem.rb.tt"),  File.join(target, "lib/#{dir_name}.rb"),         opts)
      template(File.join("newgem/lib/pawnee/newgem/version.rb.tt"), File.join(target, "lib/#{folder_name}/version.rb"), opts)
      template(File.join("newgem/lib/pawnee/newgem/base.rb.tt"), File.join(target, "lib/#{folder_name}/base.rb"), opts)
      template(File.join("newgem/spec/spec_helper.rb.tt"),   File.join(target, "spec/spec_helper.rb"), opts)
      template(File.join("newgem/spec/base_spec.rb.tt"),   File.join(target, "spec/base_spec.rb"), opts)
      template(File.join("newgem/spec/vagrant/Vagrantfile.tt"),     File.join(target, "spec/vagrant/Vagrantfile"), opts)
      template(File.join("newgem/spec/vagrant/vagrant.rb.tt"),      File.join(target, "spec/vagrant/vagrant.rb"), opts)
      if options[:bin]
        template(File.join("newgem/bin/newgem.tt"),          File.join(target, 'bin', name),              opts)
      end
      Bundler.ui.info "Initializating git repo in #{target}"
      Dir.chdir(target) { `git init`; `git add .` }
    end

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    end
  end
end