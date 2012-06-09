require 'spec_helper'

describe Pawnee::Base do
  before do
    @base = Pawnee::Base.new
  end
  
  # after(:all) do
  #   puts "Clear after base"
  #   Pawnee::Base.instance_variable_set('@recipes', nil)
  #   Pawnee::Blue.instance_eval { remove_const :Base }
  #   Pawnee.instance_eval { remove_const :Blue }
  #   Pawnee::Red.instance_eval { remove_const :Base }
  #   Pawnee.instance_eval { remove_const :Red }
  #   Pawnee.instance_eval { remove_const :CLI }
  #   require 'pawnee/cli'
  # end
  
  it "should respond to setup" do
    @base.should respond_to(:setup)
  end
  
  it "should respond to teardown" do
    @base.should respond_to(:teardown)
  end
  
  it 'should raise an exception when setup is called' do
    -> { @base.setup() }.should raise_error(RuntimeError)
  end
  
  it 'should raise an exception when teardown is called' do
    -> { @base.teardown() }.should raise_error(RuntimeError)
  end
  

  class Dep
    attr_accessor :name
    
    def initialize(name)
      @name = name
    end
  end
  
  it "should have no recipes before they are defined, but should add them after they are defined" do
    Pawnee::Base.recipes.should == nil

    # These will persist between tests
    module Pawnee
      module Red
        class Base < Pawnee::Base
          desc "setup", "setup"
          def setup
            puts "SETUP RED"
          end
        end
      end

      module Blue
        class Base < Pawnee::Base
          desc "setup", "setup"
          def setup
            puts "SETUP BLUE"
          end
        end
      end
    end

    Pawnee::Base.recipes.should == [Pawnee::Red::Base, Pawnee::Blue::Base]
  end
  
  it "should list the recipes in the order declared in the gem" do
    deps = [Dep.new('blue'), Dep.new('red')]
    Bundler.load.stub(:dependencies).and_return(deps)

    Pawnee::Base.ordered_recipes.should == [Pawnee::Blue::Base, Pawnee::Red::Base]
  
    deps = [Dep.new('red'), Dep.new('blue')]
    Bundler.load.stub(:dependencies).and_return(deps)
    Pawnee::Base.instance_variable_set('@ordered_recipes', nil)
  
    Pawnee::Base.ordered_recipes.should == [Pawnee::Red::Base, Pawnee::Blue::Base]
  end
  
  
  it "should invoke roles based on the roles passed in" do
    red = Pawnee::Red::Base.new([], {})
    red.should_receive(:setup)
    Pawnee::Red::Base.should_receive(:new).and_return(red)
    
    Pawnee::Blue::Base.should_not_receive(:new)
    
    Pawnee::Base.invoke_roles(:setup, ['red'])
  end
  
  it "should invoke roles limiting to server roles" do
    # Say we have a config file setup like this
    config_options = {
      'servers' => [
        {'domain' => 'test1.com', 'roles' => ['red']}
      ]
    }

    # But we want to pass in options with more domains
    options = {
      'servers' => [
        {'domain' => 'test1.com', 'roles' => ['red']},
        {'domain' => 'test2.com', 'roles' => ['blue', 'red']}
      ]
    }

    Pawnee::Base.should_receive(:config_options).at_least(:once).and_return(config_options)
    
    red = Pawnee::Red::Base.new([], options)
    red.should_receive(:setup).twice
    Pawnee::Red::Base.should_receive(:new).with([], options).and_return(red)
    
    blue = Pawnee::Blue::Base.new([], options)
    blue.should_receive(:setup).once
    Pawnee::Blue::Base.should_receive(:new).with([], options).and_return(blue)
    
    Pawnee::Base.invoke_roles(:setup, ['red', 'blue'], options)

  end
  
  it "should invoke for each server when doing an individual recipe's setup task" do
    options = {
      'servers' => [
        {'domain' => 'test1.com', 'roles' => ['red']},
        {'domain' => 'test2.com', 'roles' => ['red']}
      ]
    }
    
    Pawnee::Base.should_receive(:config_options).at_least(:once).and_return(options)
    
    red = Pawnee::Red::Base.new([], options)
    red.should_receive(:setup).twice
    Pawnee::Red::Base.should_receive(:new).and_return(red)

    Pawnee::Blue::Base.should_not_receive(:new)
    
    Pawnee::CLI.start(['red', 'setup'])
    
  end
  
  it "should call all setup methods when called with setup from the command line" do
    options = {
      'servers' => [
        {'domain' => 'test1.com', 'roles' => ['red']},
        {'domain' => 'test2.com', 'roles' => ['red', 'blue']}
      ]
    }
    
    Pawnee::Base.should_receive(:config_options).at_least(:once).and_return(options)
    
    red = Pawnee::Red::Base.new([], options)
    red.should_receive(:setup).twice
    Pawnee::Red::Base.should_receive(:new).and_return(red)

    blue = Pawnee::Blue::Base.new([], options)
    blue.should_receive(:setup).once
    Pawnee::Blue::Base.should_receive(:new).with([], options).and_return(blue)
    
    Pawnee::CLI.start(['setup'])
  end

  
end