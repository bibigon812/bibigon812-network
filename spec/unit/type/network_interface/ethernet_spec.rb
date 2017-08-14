require 'spec_helper'

described_type = Puppet::Type.type(:network_interface)

describe described_type do
  let :provider do
    described_class.provide(:fake_provider) do
      attr_accessor :property_hash
      def create; end
      def destroy; end
      def exist?; get(:ensure) == :present; end
      mk_resource_methods
    end
  end

  before do
    described_class.stubs(:defaultprovider).returns provider
  end

  describe 'when validating attributes' do
    [:mac].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'mac' do
    it 'should support 00:00:00:00:00:00 as a value' do
      expect { described_class.new(name: 'eth0', mac: '00:00:00:00:00:00') }.to_not raise_error
    end

    it 'should support 00-00-00-00-00-00 as a value' do
      expect { described_class.new(name: 'eth0', mac: '00-00-00-00-00-00') }.to_not raise_error
    end

    it 'should support 000000000000 as a value' do
      expect { described_class.new(name: 'eth0', mac: '000000000000') }.to_not raise_error
    end

    it 'should not support G00000000000 as a value' do
      expect { described_class.new(name: 'eth0', mac: 'G00000000000') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should not support \'\' as a value' do
      expect { described_class.new(name: 'eth0', mac: '') }.to raise_error Puppet::Error, /Invalid value/
    end
  end
end
