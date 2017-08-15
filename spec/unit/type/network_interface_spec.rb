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

    describe 'type' do
      it 'should contain :ethernet' do
        expect(described_class.new(name: 'eth1')[:type]).to eq(:ethernet)
      end

      it 'should contain :bonding' do
        expect(described_class.new(name: 'bond0')[:type]).to eq(:bonding)
      end

      it 'should contain :vlan' do
        expect(described_class.new(name: 'vlan100')[:type]).to eq(:vlan)
      end

      it 'should contain :loopback' do
        expect(described_class.new(name: 'lo')[:type]).to eq(:loopback)
      end
    end

    describe 'state' do
      it 'should contain :up' do
        expect(described_class.new(name: 'eth1')[:state]).to eq(:up)
      end

      it 'should contain :up' do
        expect(described_class.new(name: 'bond0')[:state]).to eq(:up)
      end

      it 'should contain :up' do
        expect(described_class.new(name: 'vlan100')[:state]).to eq(:up)
      end
    end

    describe 'bond_lacp_rate' do
      it 'should contain :slow' do
        expect(described_class.new(name: 'bond0')[:bond_lacp_rate]).to eq(:slow)
      end

      it 'should support fast as a value' do
        expect { described_class.new(name: 'bond0', bond_lacp_rate: 'fast') }.to_not raise_error
      end

      it 'should support slow as a value' do
        expect { described_class.new(name: 'bond0', bond_lacp_rate: :slow) }.to_not raise_error
      end

      it 'should contain fast' do
        expect(described_class.new(name: 'bond0', bond_lacp_rate: 'fast')[:bond_lacp_rate]).to eq(:fast)
      end
    end

    describe 'bond_miimon' do
      it 'should support 1500 as a value' do
        expect { described_class.new(name: 'bond0', bond_miimon: 100) }.to_not raise_error
      end

      it 'should not support \'1500\' as a value' do
        expect { described_class.new(name: 'bond0', bond_miimon: '100') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 10000 as a value' do
        expect { described_class.new(name: 'bond0', bond_miimon: 10000) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 1 as a value' do
        expect { described_class.new(name: 'bond0', bond_miimon: -1) }.to raise_error Puppet::Error, /Invalid value/
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

    describe 'bond_xmit_hash_policy' do
      it 'should contain slow' do
        expect(described_class.new(name: 'bond0')[:bond_xmit_hash_policy]).to eq(:'layer3+4')
      end

      it 'should not support layer5 as a value' do
        expect { described_class.new(name: 'bond0', bond_xmit_hash_policy: 'slayer5') }.to raise_error Puppet::Error, /Invalid value/
      end

      %w{layer2 layer3+4}.each do |xmit_hash_policy|
        it "should support #{xmit_hash_policy} as a value" do
          expect { described_class.new(name: 'bond0', bond_xmit_hash_policy: xmit_hash_policy) }.to_not raise_error
        end

        it "should contain #{xmit_hash_policy}" do
          expect(described_class.new(name: 'bond0', bond_xmit_hash_policy: xmit_hash_policy)[:bond_xmit_hash_policy]).to eq(:"#{xmit_hash_policy}")
        end
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

    describe 'parent' do
      it 'should support eth0 as value' do
        expect { described_class.new(name: 'eth0', parent: 'eth0') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should support eth0 as value' do
        expect { described_class.new(name: 'vlan100', parent: 'eth0') }.to_not  raise_error
      end
    end

    describe 'vlanid' do
      it 'should support 100 as a value' do
        expect { described_class.new(name: 'vlan100', vlanid: 100) }.to_not raise_error
      end

      it 'should support 100 as a value' do
        expect { described_class.new(name: 'vlan100', vlanid: 100) }.to_not raise_error
      end

      it 'should not support \'100\' as a value' do
        expect { described_class.new(name: 'vlan100', vlanid: '100') }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 4096 as a value' do
        expect { described_class.new(name: 'vlan100', vlanid: 4096) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should not support 0 as a value' do
        expect { described_class.new(name: 'eth0', vlanid: 100) }.to raise_error Puppet::Error, /Invalid value/
      end

      it 'should contain 200' do
        expect(described_class.new(name: 'vlan200', vlanid: 200)[:vlanid]).to eq(200)
      end

      it 'should contain 100' do
        expect(described_class.new(name: 'vlan100')[:vlanid]).to eq(100)
      end

      it 'should contain 100' do
        expect(described_class.new(name: 'vlan500')[:vlanid]).to eq(500)
      end
    end
  end

  describe 'when autorequiring' do
    let(:catalog) { Puppet::Resource::Catalog.new }

    it 'should require bond0' do
      vlan = described_class.new(name: 'vlan100', parent: 'bond0')
      bond = described_class.new(name: 'bond0', bond_slaves: %w{eth0})
      eth  = described_class.new(name: 'eth0')
      catalog.add_resource vlan
      catalog.add_resource bond
      catalog.add_resource eth
      vlan_reqs = vlan.autorequire
      bond_reqs = bond.autorequire

      expect(vlan_reqs.size).to eq(1)
      expect(vlan_reqs[0].source).to eq(bond)
      expect(vlan_reqs[0].target).to eq(vlan)

      expect(bond_reqs.size).to eq(1)
      expect(bond_reqs[0].source).to eq(eth)
      expect(bond_reqs[0].target).to eq(bond)
    end
  end
end
