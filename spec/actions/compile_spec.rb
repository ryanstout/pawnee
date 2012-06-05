require 'spec_helper'
require 'pawnee/base'


# NOTE: These are designed to run in order on vagrant
describe "compile actions" do
  before do
    @base = Pawnee::Base.new
    @base.destination_connection = VagrantManager.connect
  end
  
  it 'should install a package' do
    @base.install_packages('libpcre3', 'libpcre3-dev', 'libpcrecpp0', 'libssl-dev', 'zlib1g-dev')
    @base.as_root do
      @base.exec('rm /usr/local/sbin/nginx')
    end
    
    @base.exec('which nginx').should == ''
    
    @base.compile('http://nginx.org/download/nginx-1.2.0.tar.gz', '/home/vagrant/nginx/', {configure: '--sbin-path=/usr/local/sbin', :bin_file => 'nginx'})
    
    @base.exec('which nginx').should_not == ''
  end
  
end

