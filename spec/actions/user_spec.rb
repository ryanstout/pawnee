require 'spec_helper'
require 'pawnee/base'


# NOTE: These are designed to run in order on vagrant
describe Pawnee::Base do
  before do
    @base = Pawnee::Base.new
    @base.destination_connection = VagrantManager.connect
  end
  
  it "should create a user" do
    # @base.create_user(
    #   name: 'Ryan Stout',
    #   login: 'ryan'
    # )
  end
end