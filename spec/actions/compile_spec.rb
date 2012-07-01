require 'spec_helper'
require 'pawnee/base'


# NOTE: These are designed to run in order on vagrant
describe "compile actions" do
  before do
    @base = Pawnee::Base.new
    @base.destination_connection = VagrantManager.connect
  end
  
  it 'should install a package and track modification' do
    @base.as_root do
      @base.remove_file("/usr/local/bin/redis-server")
    end
    @base.exec('which redis-server', :log_stderr => false).should == ''
    @base.modified?.should == false
    
    @base.compile('http://redis.googlecode.com/files/redis-2.4.15.tar.gz', '/home/vagrant/redis-server/', {:skip_configure => true, :bin_file => 'redis-server'})
    
    @base.exec('which redis-server', :log_stderr => false).should_not == ''
    
    @base.modified?.should == true
  end
  
  
end

