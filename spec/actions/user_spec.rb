require 'spec_helper'
require 'pawnee/base'


# NOTE: These are designed to run in order on vagrant
describe "user actions" do
  before do
    @base = Pawnee::Base.new
    @base.destination_connection = VagrantManager.connect
  end
  
  def user_exists?(login)
    _, _, exit_code, _ = @base.exec("id -u #{login}", true)
    return exit_code == 0
  end
  
  it "should create a user" do
    @base.create_user(
      name: 'Test Blue',
      login: 'blue'
    )
    
    user_exists?('blue').should == true
  end
  
  it "should shouldn't recreate a user" do
    @base.should_receive(:say_status).with(:user_exists, 'blue', :blue)
    @base.create_user(
      name: 'Test Blue',
      login: 'blue'
    )
  end
  
  it "should modify a user" do
    # @base.should_receive(:exec).any_number_of_times.ordered.with('id -u blue', true).and_return(["1002\n", '', 0, nil])
    # @base.should_receive(:exec).any_number_of_times.ordered.with('id -u blue', true).and_return(["1002\n", '', 0, nil])
    # @base.should_receive(:exec).any_number_of_times.ordered.with('id -g blue').and_return("1002\n")
    # @base.should_receive(:exec).any_number_of_times.ordered.with('groups blue').and_return("blue: blue")
    # @base.should_receive(:exec).once.ordered.with('useradd -c "comment" blue').and_return('')
    @base.create_user(
      name: 'Test Blue',
      login: 'blue',
      comment: 'comment'
    )
  end
  
  it "should delete a user" do
    user_exists?('blue').should == true
  
    @base.delete_user('blue')
  
    user_exists?('blue').should == false
  end
end