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
    [:parent].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'parent' do
    it 'should support foo as value' do
      expect { described_class.new(name: 'foo', parent: 'foo') }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should support eth0 as value' do
      expect { described_class.new(name: 'vlan100', parent: 'eth0') }.to_not  raise_error
    end
  end

  describe 'vlanid' do
    it 'should support 100 as a value' do
      expect { described_class.new(name: 'vlan100') }.to_not raise_error
    end

    it 'should contain 200' do
      expect(described_class.new(name: 'vlan200')[:vlanid]).to eq(200)
    end

    it 'should contain 300' do
      expect(described_class.new(name: 'vlan300')[:vlanid]).to eq(300)
    end
  end

  describe 'when autorequiring' do
    let(:catalog) { Puppet::Resource::Catalog.new }

    it 'should require bond0' do
      vlan  = described_class.new(name: 'vlan100', parent: 'bond0')
      bond = described_class.new(name: 'bond0')
      catalog.add_resource vlan
      catalog.add_resource bond
      vlan_reqs = vlan.autorequire

      expect(vlan_reqs.size).to eq(1)
      expect(vlan_reqs[0].source).to eq(bond)
      expect(vlan_reqs[0].target).to eq(vlan)
    end
  end
end
