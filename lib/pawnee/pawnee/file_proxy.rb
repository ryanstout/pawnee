require 'net/sftp'

module Pawnee
  class FileProxy
    attr_accessor :connection
  
    def initialize(connection)
      self.connection = connection
    end
  
    def exists?(path)
      begin
        res = connection.sftp.stat!(path)
        return res
      rescue Net::SFTP::StatusException
        return false
      end
    
      return true
    end
  end
end