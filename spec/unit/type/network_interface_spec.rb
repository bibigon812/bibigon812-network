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

    [:ipaddress, :mtu].each do |property|
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
        expect { described_class.new(name: 'eth0', ensure: :absent) }.to_not raise_error
      end

      it 'should support :present' do
        expect { described_class.new(name: 'eth0', ensure: :present) }.to_not raise_error
      end

      it 'should support :enabled' do
        expect { described_class.new(name: 'eth0', ensure: :enabled) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should support :disabled' do
        expect { described_class.new(name: 'eth0', ensure: :disabled) }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe 'ipaddress' do
      it 'should support 10.0.0.1/24 as a value' do
        expect { described_class.new(name: 'eth0', ipaddress: '10.0.0.1/24') }.to_not raise_error
      end

      it 'should not support 500.0.0.1/24 as a value' do
        expect { described_class.new(name: 'eth0', ipaddress: '500.0.0.1/24') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 10.0.0.1 as a value' do
        expect { described_class.new(name: 'eth0', ipaddress: '10.0.0.1') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should contain 10.0.0.1' do
        expect(described_class.new(name: 'eth0', ipaddress: '10.0.0.1/24')[:ipaddress]).to eq(['10.0.0.1/24'])
      end
    end

    describe 'mtu' do
      it 'should support 1500 as a value' do
        expect { described_class.new(name: 'eth0', mtu: 1500) }.to_not raise_error
      end

      it 'should not support \'1500\' as a value' do
        expect { described_class.new(name: 'eth0', mtu: '1500') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 10000 as a value' do
        expect { described_class.new(name: 'eth0', mtu: 10000) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 1 as a value' do
        expect { described_class.new(name: 'eth0', mtu: 1) }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe 'state' do
      it 'should contain :up' do
        expect(described_class.new(name: 'eth0')[:state]).to eq(:up)
      end

      it 'should contain :up' do
        expect(described_class.new(name: 'eth0')[:state]).to eq(:up)
      end

      it 'should contain :up' do
        expect(described_class.new(name: 'eth0')[:state]).to eq(:up)
      end
    end
  end
end
