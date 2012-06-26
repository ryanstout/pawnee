require 'spec_helper'
require 'pawnee/base'


# NOTE: These are designed to run in order on vagrant
describe "inject into file" do
  before do
    @base = Pawnee::Base.new
    @base.destination_connection = VagrantManager.connect
  end
  
  it "should only inject once" do
    @base.destination_files.binwrite('/home/vagrant/test.txt', "line1\nline2\n")
    @base.append_to_file('/home/vagrant/test.txt', "line3")
    @base.destination_files.binread('/home/vagrant/test.txt').scan("line3").size.should == 1
    @base.append_to_file('/home/vagrant/test.txt', "line3")
    @base.destination_files.binread('/home/vagrant/test.txt').scan("line3").size.should == 1
  end
  
  it "should say identical the 2nd time around" do
    @base.shell.should_receive(:say_status).with(:append, "/home/vagrant/test.txt", true).once
    @base.should_receive(:say_status).with(:identical, '/home/vagrant/test.txt').once
    @base.destination_files.binwrite('/home/vagrant/test.txt', "line1\nline2\n")
    @base.append_to_file('/home/vagrant/test.txt', "line3")
    @base.destination_files.binread('/home/vagrant/test.txt').scan("line3").size.should == 1
    @base.append_to_file('/home/vagrant/test.txt', "line3")
    @base.destination_files.binread('/home/vagrant/test.txt').scan("line3").size.should == 1    
  end
  
end