require 'spec_helper'
require 'pawnee/base'


# NOTE: These are designed to run in order on vagrant
describe "compile actions" do
  before do
    @base = Pawnee::Base.new
    @base.destination_connection = VagrantManager.connect
  end
  
  it 'should install a package' do
    @base.exec('which redis-server').should == ''
    
    @base.compile('http://redis.googlecode.com/files/redis-2.4.15.tar.gz', '/home/vagrant/redis-server/', {:skip_configure => true, :bin_file => 'redis-server'})
    
    @base.exec('which redis-server').should_not == ''
  end
  
end

