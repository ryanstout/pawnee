require 'spec_helper'

describe Pawnee::Base do
  class PawneeTest < Pawnee::Base
    def self.source_root
      File.dirname(__FILE__)
    end  
  end
  
  before(:all) do
    @remote_base_path = '/home/vagrant/thortest'
    @remote_test = PawneeTest.new
    @remote_test.destination_connection = VagrantManager.connect
    @remote_test.destination_files.rm_rf(@remote_base_path)
  end

  after(:all) do
    # Close the remote connection
    @remote_test.destination_connection.close
  end

  it 'should create an empty directory remotely' do
    @remote_test.empty_directory(@remote_base_path)
    @remote_test.empty_directory(@remote_base_path + '2')
    @remote_test.destination_files.exists?(@remote_base_path)
  end
end