require File.dirname(__FILE__) + '/minitest_helper'

describe Pawnee::Base do
  before do
    @base = Pawnee::Base.new
  end
  it "must respond to setup" do
    @base.must_respond_to(:setup)
  end
  
  it "must respond to teardown" do
    @base.must_respond_to(:teardown)
  end
  
  it 'must raise an exception when setup is called' do
    -> { @base.setup }.must_raise RuntimeError
  end

  it 'must raise an exception when teardown is called' do
    -> { @base.teardown }.must_raise RuntimeError
  end
  
  it 'must come back with a proxied file object' do
    # @base.file.new.test.must_equal 'yep'
  end
  
  # it 'must return true from test' do
  #   @base.test.must_equal true
  # end
end