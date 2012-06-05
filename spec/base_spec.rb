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
end