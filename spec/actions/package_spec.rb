require 'spec_helper'
require 'pawnee/base'


# NOTE: These are designed to run in order on vagrant
describe Pawnee::Base do
  before do
    @base = Pawnee::Base.new
    @base.destination_connection = VagrantManager.connect
  end
  
  it 'should install a package' do
    @base.install_package('memcached', '1.4.7-0.1ubuntu1')
    @base.exec('which memcached').strip.should_not == ''
  end

  it 'should not reinstall a package' do
    # Should be called once for the package version query
    @base.destination_server.should_receive(:run).once.and_return('ii memcached 1.4.7-0.1ubuntu1')
    @base.install_package('memcached', '1.4.7-0.1ubuntu1')
  end
  
  it 'should return the version of a package installed' do
    @base.installed_package_version('memcached').should == '1.4.7-0.1ubuntu1'
  end
  
  it "should remove a package" do
    @base.remove_package('memcached')
    @base.exec('which memcached').should == nil
  end

  it "should not try to re-remove a package" do
    @base.destination_server.should_receive(:run).once.and_return('')
    @base.remove_package('memcached')
  end
  
  it "should not return the package version after the package has been removed" do
    @base.installed_package_version('memcached').should == nil
  end
  
end