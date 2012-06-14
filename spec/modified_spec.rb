require 'spec_helper'

describe Pawnee::Base do
  before do
    @base = Pawnee::Base.new
  end
  
  it "should track modifications" do
    @base.modified?.should == false
    @base.track_modification!
    @base.modified?.should == true
  end
  
  describe "when changing files" do
    
    before(:all) do
      @remote_base_path = '/home/vagrant/thortest'
      @remote_test = Pawnee::Base.new
      @remote_test.destination_connection = VagrantManager.connect
      @remote_test.destination_files.rm_rf(@remote_base_path)
    end

    after(:all) do
      # Close the remote connection
      @remote_test.destination_connection.close
    end
  
    it "should track modifications when a file changes" do
      @remote_test.should_receive(:track_modification!).once
      @remote_test.empty_directory(@remote_base_path + '/test1')
      @remote_test.empty_directory(@remote_base_path + '/test1')
    end
  end
end