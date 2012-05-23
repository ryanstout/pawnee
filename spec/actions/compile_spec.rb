require 'spec_helper'
require 'pawnee/base'


# NOTE: These are designed to run in order on vagrant
describe Pawnee::Base do
  before do
    @base = Pawnee::Base.new
    @base.destination_connection = VagrantManager.connect
  end
  
  it 'should install a package' do
    @base.exec('which nginx').should == nil
    
    @base.compile('http://nginx.org/download/nginx-1.2.0.tar.gz', '/home/vagrant/nginx/')
    
    @base.exec('which nginx').should_not == ''
  end
  
end

