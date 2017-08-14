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
    [:lacp_rate, :miimon, :bond_mode, :bond_slaves, :xmit_hash_policy].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe 'lacp_rate' do
    it 'should contain :slow' do
      expect(described_class.new(name: 'bond0')[:lacp_rate]).to eq(:slow)
    end

    it 'should support fast as a value' do
      expect { described_class.new(name: 'bond0', lacp_rate: 'fast') }.to_not raise_error
    end

    it 'should support slow as a value' do
      expect { described_class.new(name: 'bond0', lacp_rate: :slow) }.to_not raise_error
    end

    it 'should contain fast' do
      expect(described_class.new(name: 'bond0', lacp_rate: 'fast')[:lacp_rate]).to eq(:fast)
    end
  end

  describe 'miimon' do
    it 'should support 1500 as a value' do
      expect { described_class.new(name: 'bond0', miimon: 100) }.to_not raise_error
    end

    it 'should not support \'100\' as a value' do
      expect { described_class.new(name: 'bond0', miimon: '100') }.to_not raise_error
    end

    it 'should not support 1 as a value' do
      expect { described_class.new(name: 'bond0', miimon: -1) }.to raise_error Puppet::Error, /Invalid value/
    end
  end

  describe 'bond_mode' do
    it 'should contain layer2' do
      expect(described_class.new(name: 'bond0')[:bond_mode]).to eq(:'802.3ad')
    end

    it 'should not support balance-pzd as a value' do
      expect { described_class.new(name: 'bond0', bond_mode: 'balance-pzd') }.to raise_error Puppet::Error, /Invalid value/
    end

    %w{balance-rr active-backup balance-xor broadcast 802.3ad balance-tlb balance-alb}.each do |mode|
      it "should support #{mode} as a value" do
        expect { described_class.new(name: 'bond0', bond_mode: mode) }.to_not raise_error
      end

      it "should contain #{mode}" do
        expect(described_class.new(name: 'bond0', bond_mode: mode)[:bond_mode]).to eq(:"#{mode}")
      end
    end
  end

  describe 'bond_bond_slaves' do
    it 'should support eth0 as a value' do
      expect { described_class.new(name: 'bond0', bond_slaves: 'eth0') }.to_not raise_error
    end

    it 'should support \'[eth0 eth1]\' as a value' do
      expect { described_class.new(name: 'bond0', bond_slaves: %w{eth0 eth1}) }.to_not raise_error
    end

    it 'should not support vlan100 as a value' do
      expect { described_class.new(name: 'bond0', bond_slaves: %w{vlan100}) }.to raise_error Puppet::Error, /Invalid value/
    end

    it 'should contain \'[eth0 eth1]\'' do
      expect(described_class.new(name: 'bond0', bond_slaves: %w{eth0 eth1})[:bond_slaves]).to eq(%w{eth0 eth1})
    end
  end

  describe 'xmit_hash_policy' do
    it 'should contain slow' do
      expect(described_class.new(name: 'bond0')[:xmit_hash_policy]).to eq(:'layer3+4')
    end

    it 'should not support layer5 as a value' do
      expect { described_class.new(name: 'bond0', xmit_hash_policy: 'slayer5') }.to raise_error Puppet::Error, /Invalid value/
    end

    %w{layer2 layer3+4}.each do |xmit_hash_policy|
      it "should support #{xmit_hash_policy} as a value" do
        expect { described_class.new(name: 'bond0', xmit_hash_policy: xmit_hash_policy) }.to_not raise_error
      end

      it "should contain #{xmit_hash_policy}" do
        expect(described_class.new(name: 'bond0', xmit_hash_policy: xmit_hash_policy)[:xmit_hash_policy]).to eq(:"#{xmit_hash_policy}")
      end
    end
  end

  describe 'when autorequiring' do
    let(:catalog) { Puppet::Resource::Catalog.new }

    it 'should require eth0' do
      bond = described_class.new(name: 'bond0', bond_slaves: %w{eth0})
      eth  = described_class.new(name: 'eth0')
      catalog.add_resource bond
      catalog.add_resource eth
      reqs = bond.autorequire

      expect(reqs.size).to eq(1)
      expect(reqs[0].source).to eq(eth)
      expect(reqs[0].target).to eq(bond)
    end
  end
end
