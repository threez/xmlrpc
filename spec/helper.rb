$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
require "rubygems"
require "spec"
require 'xmlrpc'

module XmlRpc
  # Provide a simple Mock object to access the Service class directly,
  # without any Router or network traffic
  class DirectServiceMock
    def initialize(service)
      @service = service
    end
  
    def method_missing(*args)
      if @service.rpc_configured? args.first or @service.respond_to? args.first
        @service.call(args.shift, args)
      else
        super
      end
    end
  end
end