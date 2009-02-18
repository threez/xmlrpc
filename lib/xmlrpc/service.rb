module XmlRpc
  module MethodConfiguration
    # Returns the register hash. The hash contains the configration that has been 
    # applied to each method. The key is a symbol that represents the method name e.g. <em>:add</em>
    def rpc_methods_config
      @register ||= {}
    end
    
    # Returns true if the passed method has a configuration entry otherwise false
    def rpc_configured?(method)
      !rpc_methods_config[method].nil?
    end

    # sets or updates a configuration for the passed method with the passed options hash
    def configure_rpc(method, options = {})
      raise ArgumentError.new("options has to be of type hash") unless options.respond_to?(:each_pair)
      rpc_methods_config[method] = options
    end
  end 
  
  module Validations # :nodoc:
    # Validates the given options and raise an ArgumentError if there is a problem during the validation.
    def validate_rpc_params_option!(options)
      # convert to array if it isn't allready
      options[:params] = [options[:params]] unless options[:params].respond_to?(:each)
      
      # check if correct validation types are used
      unless options[:params].nil?
        for type in options[:params] do
          if Types.map_type(type).nil?
            raise ArgumentError.new("rpc option :params is incorrect, the type #{type} is unknown")
          end
        end
      end
    end
  end
  
  module Verifications # :nodoc:
    # Verifys all arguments and the method name raises Exception if any error occurs
    def verify_rpc_call_options!(method, args)
      for option_key in @register[method].keys do
        if respond_to?("verify_#{option_key}!") then
          send("verify_#{option_key}!", method, args, @register[method][option_key])
        end
      end
    end

    # Verifys that if the values have types that they should have otherwise
    # raises ArgumentError
    def verify_params!(method, args, types)
      # iterate over every defined type in the :params option
      types.inject(0) do |i, type|
        arg_type = args[i].class
        should_be = Types.map_type(type)
        
        # this is the message template for any typ error
        err_msg = "#{i+1}. parameter of #{method} has wrong type " + 
          "<#{arg_type}> use type <#{should_be}> instead"
        
        if should_be == :boolean
          if !(arg_type.name =~ /^(TrueClass|FalseClass)$/)
            raise ArgumentError.new(err_msg)
          end
        elsif should_be != arg_type
          raise ArgumentError.new(err_msg)
        end
        
        i += 1
      end
    end
  end
  
  module Types # :nodoc:
    # Returns the ruby object that is represented by the xmlrpc type
    def self.map_type(name)
      case name
      when :int, :i4, :integer, Fixnum
        Fixnum
      when :string, String
        String
      when :array, Array
        Array
      when :struct, Struct
        nil # FIXME
      when :boolean, :bool, TrueClass, FalseClass
        :boolean
      when :base64
        String
      when :datetime, :dateTime, DateTime, Time
        Time
      when :double, :float, :real, Float
        Float
      else
        nil
      end
    end
  end
  
  # The Service class represents a tiny wrapper to configure the behavior. This
  # wrapper enables you to set limitations and validations for every method. If 
  # you want, you can use the service class without configuration.
  #
  # Simple XMLRPC service that uses the class to build a service without the
  # need to write a new class.
  # 
  #  service = XmlRpc::Service.new "Math"
  #
  #  def service.add(a, b)
  #    a + b
  #  end
  #
  # To configure the method behavior use the rpc method.
  #
  #  service.rpc :add, :params => [:int, :int]
  #
  class Service
    include MethodConfiguration
    include Verifications
    include Validations
    
    # Create a new service wrapper with the passed domain as 
    # service name. The domain will be de prefix for each method
    # of that service. So if you have a service like this:
    #
    #  service = XmlRpc::Service.new "Math"
    #
    #  def service.add(a, b)
    #    a + b
    #  end
    #
    # Then a external caller will call the method like this <tt>Math.add</tt>
    def initialize(domain = nil, &block)
      instance_eval(&block) if block_given?
    end
    
    # Using the rpc method one has many options to manipulate a method. To specify
    # the method pass a symbol with the name of the method.
    #
    # == Parameter type checking
    # If you want the Service to be aware of certain types you can specifiy them
    # by passing the <em>:params</em> option
    #
    #  service.rpc :add, :params => [:int, :int]
    # 
    # The different types are:
    # * :i4 or :int to indicate a four-byte signed integer
    # * :boolean to only allow the classes TrueClass (true) and FalseClass (false)
    # * :string a text of any length
    # * :double a	double-precision signed floating point number
    # * :datetime	date/time	19980717T14:08:55 (format iso8601 will be used)
    # * :base64 a text of any lenght that contains base64 data
    # * :struct a struct object that will be translated to a ruby struct
    # * :array a normal ruby array
    def rpc(method, options = {}, &block)
      validate_rpc_params_option!(options) unless options[:params].nil?
      configure_rpc(method, options)
      
      # FIXME: use block for method definition
    end
    
    # Calls a rpc method of the service object. This method is used internaly, it
    # wraps up the whole configuration stack.
    def call(method, args = nil)
      # make verifications were possible
      if rpc_configured?(method)
        verify_rpc_call_options! method, args
      end
      send(method, *args)
    end
  end
end
