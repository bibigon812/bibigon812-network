require 'spec_helper'

described_type= Puppet::Type.type(:network_interface)

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
    [ :name ].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [ :ipaddress ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  it 'should have :name be it\'s namevar' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating values' do
    describe 'ensure' do
      it 'should support :absent' do
        expect { described_class.new(name: 'foo', ensure: :absent) }.to_not raise_error
      end

      it 'should support :present' do
        expect { described_class.new(name: 'foo', ensure: :present) }.to_not raise_error
      end

      it 'should support :enabled' do
        expect { described_class.new(name: 'foo', ensure: :enabled) }.to_not raise_error
      end

      it 'should support :disabled' do
        expect { described_class.new(name: 'foo', ensure: :disabled) }.to_not raise_error
      end
    end

    describe 'ipaddress' do
      it 'should support 10.0.0.1/24 as a value' do
        expect { described_class.new(name: 'foo', ipaddress: '10.0.0.1/24') }.to_not raise_error
      end

      it 'should not support 500.0.0.1/24 as a value' do
        expect { described_class.new(name: 'foo', ipaddress: '500.0.0.1/24') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 10.0.0.1 as a value' do
        expect { described_class.new(name: 'foo', ipaddress: '10.0.0.1') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should contain 10.0.0.1' do
        expect(described_class.new(name: 'foo', ipaddress: '10.0.0.1/24')[:ipaddress]).to eq(['10.0.0.1/24'])
      end
    end

    describe 'mac' do
      it 'should support 00:00:00:00:00:00 as a value' do
        expect { described_class.new(name: 'foo', mac: '00:00:00:00:00:00') }.to_not raise_error
      end

      it 'should support 00-00-00-00-00-00 as a value' do
        expect { described_class.new(name: 'foo', mac: '00-00-00-00-00-00') }.to_not raise_error
      end

      it 'should support 000000000000 as a value' do
        expect { described_class.new(name: 'foo', mac: '000000000000') }.to_not raise_error
      end

      it 'should not support G00000000000 as a value' do
        expect { described_class.new(name: 'foo', mac: 'G00000000000') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support \'\' as a value' do
        expect { described_class.new(name: 'foo', mac: '') }.to raise_error Puppet::Error, /Invalid value/
      end
    end
  end
end