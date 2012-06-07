require 'spec_helper'

describe Pawnee::Base do
  before do
    @base = Pawnee::Base.new
  end
  
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
        end
      end

      module Blue
        class Base < Pawnee::Base
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
end