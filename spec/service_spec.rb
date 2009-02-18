require File.join(File.dirname(__FILE__), 'helper')

describe XmlRpc::MethodConfiguration do
  before do
    class SimpleMethodConfiguration
      include XmlRpc::MethodConfiguration
    end
    
    @config = SimpleMethodConfiguration.new
  end
  
  it "should be empty after initializing" do
    @config.rpc_methods_config.size.should == 0
  end
  
  it "should remember a configuration entry" do
    options = { :params => :dateTime }
    
    @config.configure_rpc :update_time, options
    @config.rpc_configured?(:update_time).should == true
    @config.rpc_configured?(:initialize).should == false
    @config.rpc_methods_config[:update_time].should == options
  end
  
  it "should check the type of options" do
    lambda do
      @config.configure_rpc :check_balance_of_account, "options"
    end.should raise_error(ArgumentError)
  end
end

describe XmlRpc::Validations do
  before do
    class SimpleValidations
      include XmlRpc::Validations
    end
    
    @validations = SimpleValidations.new
  end
  
  it "should allow every type that is specified in the protocol" do
    options = {
      :params => [:int, :i4, :string, :double, :base64, :array, :struct, :boolean, :datetime]
    }
    
    @validations.validate_rpc_params_option!(options)
  end
  
  it "should not allow every type that is specified in the protocol" do
    options = {
      :params => [:int, :i4, :string, :double, :base64, :bad, :struct, :boolean, :datetime]
    }
    
    lambda do
      @validations.validate_rpc_params_option!(options)
    end.should raise_error(ArgumentError)
  end
  
  it "should transform params to array if it isn't allready" do
    options = { :params => :int }
    
    @validations.validate_rpc_params_option!(options)
    options[:params].respond_to? :each
  end
end

describe XmlRpc::Verifications do
  before do
    class SimpleVerifications
      include XmlRpc::Verifications
    end
    
    @verifications = SimpleVerifications.new
  end
  
  it "should verify the params options" do
    lambda do
      @verifications.verify_params! :dummy, [1, 3.2], [:int, :double]
      @verifications.verify_params! :dummy, [-2, "asdad"], [:i4, :string]
      @verifications.verify_params! :dummy, [nil, [1, 2]], [:struct, :array]
      @verifications.verify_params! :dummy, [true, "asd"], [:boolean, :base64]
      @verifications.verify_params! :dummy, [false, Time.now], [:boolean, :datetime]
    end.should_not raise_error
    
    lambda do
      @verifications.verify_params! :dummy, [1, 3.2], [:double, :int]
    end.should raise_error(ArgumentError)
    
    lambda do
      @verifications.verify_params! :dummy, [1.3, 3.2], [:i4, :string]
    end.should raise_error(ArgumentError)
    
    lambda do
      @verifications.verify_params! :dummy, [Time.now, 3.2], [:array, :base64]
    end.should raise_error(ArgumentError)
    
    lambda do
      @verifications.verify_params! :dummy, [[1, 2], Struct.new(:name)], [:struct, :double]
    end.should raise_error(ArgumentError)
  end
end

describe XmlRpc::Service, "for a simple math class" do
  before do
    service = XmlRpc::Service.new "Math" do
      rpc :add, :params => [:int, :i4] 
      rpc :opposit, :params => :boolean
    end
    
    def service.add(a, b)
      a + b
    end
    
    def service.percentile(array, percentile)
      p = array.size - (array.size * percentile / 100).to_i
      array.sort!
      p.times do # remove items
        array.shift
        array.pop
      end
      array
    end
    
    def service.opposit(bool)
      !bool
    end
    
    @service = XmlRpc::DirectServiceMock.new(service)
  end
  
  it "should return the sum of to values on calling the add method" do
    a, b = 12, 24
    @service.add(a, b).should == a + b
  end
  
  it "should return the percentiled version of the array" do
    data = [8, 5, 6, 7, 10, 434, 9, 1]
    @service.percentile(data, 90).should == [5, 6, 7, 8, 9, 10]
  end
  
  it "should return an ArgumentError if the wrong type was passed to a method" do
    lambda do
      @service.add("as", "b")
    end.should raise_error(ArgumentError)
    
    lambda do
      @service.add(12.12, 24)
    end.should raise_error(ArgumentError)
    
    @service.opposit(true).should == false
    @service.opposit(false).should == true
    lambda do
      @service.opposit(12.12)
    end.should raise_error(ArgumentError)
  end
  
  it "should be able to implement the method with the rpc method" do
    @service.rpc :sin do |x|
      Math.sin(x)
    end
    @service.sin(8) == Math.sin(8)
  end
end
