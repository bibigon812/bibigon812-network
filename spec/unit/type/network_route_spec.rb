require 'spec_helper'

described_type= Puppet::Type.type(:network_route)

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
    [:name].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:prefix, :metric, :dev, :via].each do |property|
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
        expect { described_class.new(name: '10.0.0.0/24', ensure: :absent) }.to_not raise_error
      end

      it 'should support :present' do
        expect { described_class.new(name: '10.0.0.0/24', ensure: :present) }.to_not raise_error
      end

      it 'should support :enabled' do
        expect { described_class.new(name: '10.0.0.0/24', ensure: :enabled) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should support :disabled' do
        expect { described_class.new(name: '10.0.0.0/24', ensure: :disabled) }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe 'metric' do
      it 'should support 100 as a value' do
        expect { described_class.new(name: '10.0.0.0/24', metric: 100) }.to_not raise_error
      end

      it 'should support \'100\' as a value' do
        expect { described_class.new(name: '10.0.0.0/24', metric: '100') }.to_not raise_error
      end

      it 'should not support \'100\' as a value' do
        expect { described_class.new(name: '10.0.0.0/24 100') }.to_not raise_error
      end

      it 'should not support 10000 as a value' do
        expect { described_class.new(name: '10.0.0.0/24', metric: 10000) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support -1 as a value' do
        expect { described_class.new(name: '10.0.0.0/24', metric: -1) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 200 as a value' do
        expect(described_class.new(name: '10.0.0.0/24 200')[:metric]).to eq(200)
      end
    end
  end

  # TODO:
  # describe 'when autorequiring' do
  #   let(:catalog) { Puppet::Resource::Catalog.new }
  #
  #   it 'should require bond0' do
  #     route = described_class.new(name: '10.0.0.0/24', device: 'bond0')
  #     bond = Puppet::Type.type(:network_interface).new(name: 'bond0', bond_slaves: %w{eth0})
  #     catalog.add_resource route
  #     catalog.add_resource bond
  #     route_reqs = route.autorequire
  #
  #     expect(route_reqs.size).to eq(1)
  #     expect(route_reqs[0].source).to eq(bond)
  #     expect(route_reqs[0].target).to eq(route)
  #   end
  # end
end
