require 'spec_helper'

describe Puppet::Type.type(:network_interface).provider(:iproute2) do
  describe 'instances' do
    it 'should have an instance method' do
      expect(described_class).to respond_to :instances
    end
  end

  let(:output) do
    <<-EOS
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet 10.255.0.1/32 scope global lo
       valid_lft forever preferred_lft forever
    inet 192.168.0.1/32 scope global lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:1d:5a:fb brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe1d:5afb/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:9c:76:49 brd ff:ff:ff:ff:ff:ff
    inet 172.16.32.103/24 brd 172.16.32.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe9c:7649/64 scope link
       valid_lft forever preferred_lft forever
4: ip_vti0@NONE: <NOARP> mtu 1500 qdisc noop state DOWN
    link/ipip 0.0.0.0 brd 0.0.0.0
5: bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:9c:76:49 brd ff:ff:ff:ff:ff:ff
6: bond0.100@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:9c:76:49 brd ff:ff:ff:ff:ff:ff
    inet 172.16.33.103/24 brd 172.16.32.255 scope global eth1
       valid_lft forever preferred_lft forever
EOS
  end

  context 'ip addr output' do
    before :each do
      described_class.expects(:ip).with('addr').returns output
      described_class.stubs(:cat).with('/sys/class/net/bond0/bonding/lacp_rate').returns 'slow'
      described_class.stubs(:cat).with('/sys/class/net/bond0/bonding/miimon').returns '100'
      described_class.stubs(:cat).with('/sys/class/net/bond0/bonding/mode').returns '802.3ad'
      described_class.stubs(:cat).with('/sys/class/net/bond0/bonding/xmit_hash_policy').returns 'layer3+4'
    end

    it 'should return resources' do
      expect(described_class.instances.size).to eq(6)
    end

    it 'should return the resource eth0' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq(
        {
            ensure: :enabled,
            ipaddress: %w{127.0.0.1/8 10.255.0.1/32 192.168.0.1/32},
            mtu: 65536,
            name: 'lo',
            provider: :iproute2,
            type: :eth,
        }
      )
    end

    it 'should return the resource eth0' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
        {
            ensure: :enabled,
            ipaddress: %w{10.0.2.15/24},
            mac: '08:00:27:1d:5a:fb',
            mtu: 1500,
            name: 'eth0',
            provider: :iproute2,
            type: :eth,
        }
      )
    end

    it 'should return the resource eth0' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq(
        {
            ensure: :enabled,
            ipaddress: %w{172.16.32.103/24},
            mac: '08:00:27:9c:76:49',
            mtu: 1500,
            name: 'eth1',
            provider: :iproute2,
            type: :eth,
        }
      )
    end

    it 'should return the resource eth0' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq(
        {
            ensure: :disabled,
            ipaddress: [],
            mtu: 1500,
            name: 'ip_vti0',
            provider: :iproute2,
            type: :eth,
        }
      )
    end

    it 'should return the resource eth0' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq(
        {
            bond_lacp_rate: 'slow',
            bond_miimon: 100,
            bond_mode: '802.3ad',
            bond_xmit_hash_policy: 'layer3+4',
            ensure: :enabled,
            ipaddress: [],
            mac: '08:00:27:9c:76:49',
            mtu: 1500,
            name: 'bond0',
            provider: :iproute2,
            type: :bond,
        }
      )
    end

    it 'should return the resource eth0' do
      expect(described_class.instances[5].instance_variable_get('@property_hash')).to eq(
        {
            ensure: :enabled,
            ipaddress: %w{172.16.33.103/24},
            mac: '08:00:27:9c:76:49',
            mtu: 1500,
            name: 'bond0.100',
            parent: 'bond0',
            provider: :iproute2,
            type: :vlan,
        }
      )
    end
  end

  let(:provider) do
    described_class.new(
        ensure: :enabled,
        ipaddress: %w{172.16.32.108/24},
        mtu: 1500,
        name: 'eth1',
        provider: :iproute2,
    )
  end

  let(:resource) do
    Puppet::Type.type(:network_interface).new(
        name: 'eth1',
    )
  end

  describe 'prefetch' do
    let(:resources) do
      {
          eth1: resource
      }
    end

    before :each do
      described_class.stubs(:ip).with('addr').returns output
      described_class.stubs(:cat).with('/sys/class/net/bond0/bonding/lacp_rate').returns 'slow'
      described_class.stubs(:cat).with('/sys/class/net/bond0/bonding/miimon').returns '100'
      described_class.stubs(:cat).with('/sys/class/net/bond0/bonding/mode').returns '802.3ad'
      described_class.stubs(:cat).with('/sys/class/net/bond0/bonding/xmit_hash_policy').returns 'layer3+4'
    end

    it 'should find provider for resource' do
      described_class.prefetch(resources)
      expect(resources.values.first.provider.name).to eq('eth1')
    end
  end


  describe '#create' do
    before :each do
      provider.stubs(:exists?).returns(false)
    end

    context 'an ethernet interface' do
      let(:resource) do
        Puppet::Type.type(:network_interface).new(
            name: 'eth1',
            ipaddress: %w{10.255.255.1/24 172.31.255.1/24},
            mac: '01:23:45:67:89:ab',
            mtu: 1500
        )
      end
      it 'with all params' do
        resource.provider = provider
        provider.expects(:ip).with(%w{addr add 10.255.255.1/24 dev eth1})
        provider.expects(:ip).with(%w{addr add 172.31.255.1/24 dev eth1})
        provider.expects(:ip).with(%w{link set dev eth1 mtu 1500})
        provider.expects(:ip).with(%w{link set dev eth1 address 01:23:45:67:89:ab})
        provider.expects(:ip).with(%w{link set dev eth1 up})
        provider.create
      end
    end

    context 'a vlan interface' do
      let(:resource) do
        Puppet::Type.type(:network_interface).new(
            name: 'vlan100',
            ipaddress: %w{10.255.255.1/24 172.31.255.1/24},
            mac: '01:23:45:67:89:ab',
            mtu: 1500,
            parent: 'eth0'
        )
      end

      it 'with all params' do
        resource.provider = provider
        provider.expects(:ip).with(%w{link add name vlan100 link eth0 type vlan id 100})
        provider.expects(:ip).with(%w{addr add 10.255.255.1/24 dev vlan100})
        provider.expects(:ip).with(%w{addr add 172.31.255.1/24 dev vlan100})
        provider.expects(:ip).with(%w{link set dev vlan100 mtu 1500})
        provider.expects(:ip).with(%w{link set dev vlan100 address 01:23:45:67:89:ab})
        provider.expects(:ip).with(%w{link set dev vlan100 up})
        provider.create
      end
    end
  end

  describe '#destroy' do

  end
end