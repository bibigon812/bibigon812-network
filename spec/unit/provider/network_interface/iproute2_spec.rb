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
5: bond0: <NO-CARRIER,BROADCAST,MULTICAST,MASTER,UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:9c:76:49 brd ff:ff:ff:ff:ff:ff
6: vlan100@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:9c:76:49 brd ff:ff:ff:ff:ff:ff
    inet 172.16.33.103/24 brd 172.16.32.255 scope global eth1
       valid_lft forever preferred_lft forever
7: vlan200@bond0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 08:00:27:9c:76:49 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.1/24 scope global vlan100
       valid_lft forever preferred_lft forever
    inet 172.16.0.1/24 scope global vlan100
       valid_lft forever preferred_lft forever
    inet 192.168.0.1/24 scope global vlan100
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe9c:7649/64 scope link
       valid_lft forever preferred_lft forever
EOS
  end

  context 'ip address output' do
    before :each do
      described_class.expects(:ip).with('address').returns output
      File.stubs(:read).with('/sys/class/net/bond0/bonding/lacp_rate').returns 'slow'
      File.stubs(:read).with('/sys/class/net/bond0/bonding/miimon').returns '100'
      File.stubs(:read).with('/sys/class/net/bond0/bonding/mode').returns '802.3ad'
      File.stubs(:read).with('/sys/class/net/bond0/bonding/xmit_hash_policy').returns 'layer3+4'
      File.stubs(:read).with('/sys/class/net/bonding_masters').returns ''
    end

    it 'should return resources' do
      expect(described_class.instances.size).to eq(7)
    end

    it 'should return the resource lo' do
      expect(described_class.instances[0].instance_variable_get('@property_hash')).to eq(
        {
          ensure:    :present,
          ipaddress: %w{127.0.0.1/8 10.255.0.1/32 192.168.0.1/32},
          mtu:       65536,
          name:      'lo',
          provider:  :iproute2,
          state:     :up,
          type:      :loopback,
        }
      )
    end

    it 'should return the resource eth0' do
      expect(described_class.instances[1].instance_variable_get('@property_hash')).to eq(
        {
          ensure:    :present,
          ipaddress: %w{10.0.2.15/24},
          mac:       '08:00:27:1d:5a:fb',
          mtu:       1500,
          name:      'eth0',
          provider:  :iproute2,
          state:     :up,
          type:      :ethernet,
        }
      )
    end

    it 'should return the resource eth1' do
      expect(described_class.instances[2].instance_variable_get('@property_hash')).to eq(
        {
          ensure:    :present,
          ipaddress: %w{172.16.32.103/24},
          mac:       '08:00:27:9c:76:49',
          mtu:       1500,
          name:      'eth1',
          provider:  :iproute2,
          state:     :up,
          type:      :ethernet,
        }
      )
    end

    it 'should return the resource ip_vti0' do
      expect(described_class.instances[3].instance_variable_get('@property_hash')).to eq(
        {
          ensure:    :present,
          ipaddress: [],
          mtu:       1500,
          name:      'ip_vti0',
          provider:  :iproute2,
          state:     :down,
          type:      :unknown,
        }
      )
    end

    it 'should return the resource bond0' do
      expect(described_class.instances[4].instance_variable_get('@property_hash')).to eq(
        {
          bond_lacp_rate:        :slow,
          bond_miimon:           100,
          bond_mode:             '802.3ad',
          bond_slaves:           [],
          bond_xmit_hash_policy: 'layer3+4',
          ensure:                :present,
          ipaddress:             [],
          mac:                   '08:00:27:9c:76:49',
          mtu:                   1500,
          name:                  'bond0',
          provider:              :iproute2,
          state:                 :up,
          type:                  :bonding,
        }
      )
    end

    it 'should return the resource vlan100' do
      expect(described_class.instances[5].instance_variable_get('@property_hash')).to eq(
        {
          ensure:    :present,
          ipaddress: %w{172.16.33.103/24},
          mac:       '08:00:27:9c:76:49',
          mtu:       1500,
          name:      'vlan100',
          parent:    'bond0',
          provider:  :iproute2,
          state:     :up,
          vlanid:    100,
          type:      :vlan,
        }
      )
    end

    it 'should return the resource vlan200' do
      expect(described_class.instances[6].instance_variable_get('@property_hash')).to eq(
        {
          ensure:    :present,
          ipaddress: %w{10.0.0.1/24 172.16.0.1/24 192.168.0.1/24},
          mac:       '08:00:27:9c:76:49',
          mtu:       1500,
          name:      'vlan200',
          parent:    'bond0',
          provider:  :iproute2,
          state:     :up,
          vlanid:    200,
          type:      :vlan,
        }
      )
    end
  end

  let(:provider) do
    described_class.new(
      ensure:    :present,
      ipaddress: [],
      mtu:       1500,
      name:      'eth1',
      provider:  :iproute2,
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
      described_class.expects(:ip).with('address').returns output
      File.expects(:read).with('/sys/class/net/bond0/bonding/lacp_rate').returns 'slow'
      File.expects(:read).with('/sys/class/net/bond0/bonding/miimon').returns '100'
      File.expects(:read).with('/sys/class/net/bond0/bonding/mode').returns '802.3ad'
      File.expects(:read).with('/sys/class/net/bond0/bonding/xmit_hash_policy').returns 'layer3+4'
      File.stubs(:read).with('/sys/class/net/bonding_masters').returns ''
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
          name:      'eth1',
          ipaddress: %w{10.255.255.1/24 172.31.255.1/24},
          mac:       '01:23:45:67:89:ab',
          mtu:       1500
        )
      end
      it 'with all params' do
        resource.provider = provider
        provider.create
      end
    end

    context 'a vlan interface' do
      let(:resource) do
        Puppet::Type.type(:network_interface).new(
          name:      'vlan100',
          ipaddress: %w{10.255.255.1/24 172.31.255.1/24},
          mac:       '01:23:45:67:89:ab',
          mtu:       1500,
          parent:    'eth0'
        )
      end

      it 'with all params' do
        resource.provider = provider
        provider.expects(:ip).with(%w{link add name vlan100 link eth0 type vlan id 100})
        provider.expects(:ip).with(%w{address add 10.255.255.1/24 dev vlan100})
        provider.expects(:ip).with(%w{address add 172.31.255.1/24 dev vlan100})
        provider.expects(:ip).with(%w{link set dev vlan100 mtu 1500})
        provider.expects(:ip).with(%w{link set dev vlan100 address 01:23:45:67:89:ab})
        provider.expects(:ip).with(%w{link set dev vlan100 up})
        provider.create
      end
    end

    context 'a bond interface' do
      let(:resource) do
        Puppet::Type.type(:network_interface).new(
          bond_slaves: ['eth0',],
          name:        'bond0',
          ipaddress:   [],
          mac:         '01:23:45:67:89:ab',
          mtu:         1500
        )
      end

      before :each do
        File.expects(:directory?).with('/sys/class/net/bond0/bonding').returns true
        File.expects(:symlink?).with('/sys/class/net/eth0').returns true
        File.expects(:read).with('/sys/class/net/eth0/operstate').returns 'up'
        provider.expects(:ip).with(%w{link set dev eth0 down})
        provider.expects(:ip).with(%w{link set dev eth0 up})
        File.expects(:write).with('/sys/class/net/bond0/bonding/lacp_rate', 'slow').returns 4
        File.expects(:write).with('/sys/class/net/bond0/bonding/miimon', '100').returns 3
        File.expects(:write).with('/sys/class/net/bond0/bonding/mode', '802.3ad').returns 7
        File.expects(:write).with('/sys/class/net/bond0/bonding/xmit_hash_policy', 'layer3+4').returns 8
        File.expects(:write).with('/sys/class/net/bond0/bonding/slaves', '+eth0').returns 5
        File.stubs(:read).with('/sys/class/net/bonding_masters').returns ''
      end

      it 'without bonding driver' do
        resource.provider = provider
        File.expects(:exists?).with('/sys/class/net/bonding_masters').returns false
        provider.expects(:modprobe).with(%w{bonding})
        File.expects(:read).with('/sys/class/net/bonding_masters').returns 'bond0'
        File.expects(:write).with('/sys/class/net/bonding_masters', '-bond0').returns 6
        File.expects(:write).with('/sys/class/net/bonding_masters', '+bond0').returns 6
        provider.expects(:ip).with(%w{link set dev bond0 mtu 1500})
        provider.expects(:ip).with(%w{link set dev bond0 address 01:23:45:67:89:ab})
        provider.expects(:ip).with(%w{link set dev bond0 up})
        provider.create
      end

      it 'with bonding driver' do
        resource.provider = provider
        File.expects(:exists?).with('/sys/class/net/bonding_masters').returns true
        File.expects(:write).with('/sys/class/net/bonding_masters', '+bond0').returns 6
        provider.expects(:ip).with(%w{link set dev bond0 mtu 1500})
        provider.expects(:ip).with(%w{link set dev bond0 address 01:23:45:67:89:ab})
        provider.expects(:ip).with(%w{link set dev bond0 up})
        provider.create
      end
    end
  end

  describe '#destroy' do
    before :each do
      provider.stubs(:exists?).returns true
    end

    context 'an ethernet interface' do
      let(:resource) do
        Puppet::Type.type(:network_interface).new(
          ensure:    :absent,
          name:      'eth1',
          ipaddress: %w{10.255.255.1/24 172.31.255.1/24},
          mac:       '01:23:45:67:89:ab',
          mtu:       1500
        )
      end

      let(:provider) do
        described_class.new(
          ensure:    :present,
          ipaddress: [],
          mtu:       1500,
          name:      'eth1',
          provider:  :iproute2,
          state:     :up,
          type:      :ethernet,
        )
      end


      it 'with all params' do
        provider.stubs(:interface_exists?).returns true
        provider.expects(:ip).with(%w{link set dev eth1 down})
        resource.provider = provider
        provider.destroy
      end
    end

    context 'a vlan interface' do
      let(:resource) do
        Puppet::Type.type(:network_interface).new(
          ensure:    :absent,
          name:      'vlan100',
          ipaddress: %w{10.255.255.1/24 172.31.255.1/24},
          mac:       '01:23:45:67:89:ab',
          mtu:       1500,
          parent:    'eth0'
        )
      end

      let(:provider) do
        described_class.new(
          ensure:    :present,
          ipaddress: [],
          mtu:       1500,
          name:      'vlan100',
          provider:  :iproute2,
          state:     :up,
          vlanid:    100,
          type:      :vlan
        )
      end

      it 'with all params' do
        resource.provider = provider
        provider.stubs(:interface_exists?).returns true
        provider.expects(:ip).with(%w{link set dev vlan100 down})
        provider.expects(:ip).with(%w{link delete dev vlan100 type vlan})
        provider.destroy
      end
    end
  end

  describe '#bond_slaves=(value)' do
    before :each do
      provider.stubs(:exists?).returns true
      File.stubs(:directory?).with('/sys/class/net/bond0/bonding').returns true
      File.stubs(:symlink?).with('/sys/class/net/eth2').returns true
      File.stubs(:symlink?).with('/sys/class/net/eth3').returns true
    end

    context 'an bond interface' do
      let(:provider) do
        described_class.new(
          name:     'bond0',
          provider: :iproute2,
          state:    :up,
          type:     :bonding,
        )
      end

      it 'should add bond_slaves' do
        File.stubs(:read).with('/sys/class/net/bonding_masters').returns ''
        File.expects(:read).with('/sys/class/net/eth2/operstate').returns 'up'
        File.expects(:read).with('/sys/class/net/eth3/operstate').returns 'up'
        File.expects(:write).with('/sys/class/net/bond0/bonding/slaves', '+eth2').returns 5
        File.expects(:write).with('/sys/class/net/bond0/bonding/slaves', '+eth3').returns 5
        provider.expects(:ip).with(%w{link set dev bond0 down})
        provider.expects(:ip).with(%w{link set dev eth2 down})
        provider.expects(:ip).with(%w{link set dev eth3 down})
        provider.expects(:ip).with(%w{link set dev bond0 up})
        provider.expects(:ip).with(%w{link set dev eth2 up})
        provider.expects(:ip).with(%w{link set dev eth3 up})
        provider.bond_slaves = %w{eth2 eth3}
      end
    end
  end
end
