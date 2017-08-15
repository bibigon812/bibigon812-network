require 'spec_helper'

describe 'network::interface::config' do
  let(:facts) do
    {
        os: {
            architecture: 'x86_64',
            family: 'RedHat',
            hardware: 'x86_64',
            name: 'CentOS',
            release: {
                full: '7.1.1503',
                major: '7',
                minor: '1'
            },
            selinux: {
                enabled: false
            }
        }
    }
  end

  let(:environment) { :sandbox }

  context 'eth0' do
    let(:title) { 'eth0' }
    let(:params) do
      {
          ipaddress:  %w{10.0.0.1/24},
          config_dir: '/etc/sysconfig/network-scripts',
          type:       :hw,
          routes:     [
              {
                  ensure:  :present,
                  device:  'eth0',
                  metric:  100,
                  nexthop: '192.168.0.1',
                  prefix:  '10.0.0.0/8',
              },
              {
                  ensure:  :present,
                  device:  'eth0',
                  metric:  0,
                  nexthop: '192.168.0.1',
                  prefix:  '172.16.0.0/12',
              },
          ],
      }
    end

    it 'should contain ifcfg-eth0' do
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-eth0')
        .with_content(<<-OES
#
# Managed by Puppet in the sandbox environment
#
BOOTPROTO=none
DEVICE=eth0
IPADDR=10.0.0.1
PREFIX=24
ONBOOT=yes
USERCTL=no
NM_CONTROLLED=no
TYPE=Ethernet
      OES
        )
    end

    it 'should contain route-eth0' do
      is_expected.to contain_file('/etc/sysconfig/network-scripts/route-eth0').
          with_content(<<-OES
#
# Managed by Puppet in the sandbox environment
#
10.0.0.0/8 via 192.168.0.1 dev eth0 metric 100
172.16.0.0/12 via 192.168.0.1 dev eth0 metric 0
          OES
          )
    end
  end

  context 'bond0' do
    let(:title) { 'bond0' }
    let(:params) do
      {
          bond_lacp_rate:        :fast,
          bond_miimon:           100,
          bond_mode:             '802.3ad',
          bond_slaves:           [:eth1],
          bond_xmit_hash_policy: :layer2,
          ipaddress:             %w{10.0.0.1/24 172.16.0.1/24 192.168.0.1/24},
          config_dir:            '/etc/sysconfig/network-scripts',
          type:                  :bond,
      }
    end

    it do
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-bond0').with_content(<<-OES
#
# Managed by Puppet in the sandbox environment
#
BOOTPROTO=none
DEVICE=bond0
IPADDR=10.0.0.1
PREFIX=24
IPADDR1=172.16.0.1
PREFIX1=24
IPADDR2=192.168.0.1
PREFIX2=24
ONBOOT=yes
USERCTL=no
NM_CONTROLLED=no
BONDING_OPTS="mode=802.3ad miimon=100 lacp_rate=fast xmit_hash_policy=layer2"
TYPE=Bond
OES
        )
    end
  end

  context 'bond0.100' do
    let(:title) { 'bond0.100' }
    let(:params) do
      {
          ipaddress: %w{10.0.0.1/24},
          config_dir: '/etc/sysconfig/network-scripts',
          type: :vlan,
          vlanid: 100,
      }
    end

    it 'should contain ifcfg-bond0.100' do
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-bond0.100').with_content(<<-OES
#
# Managed by Puppet in the sandbox environment
#
BOOTPROTO=none
DEVICE=bond0.100
IPADDR=10.0.0.1
PREFIX=24
ONBOOT=yes
USERCTL=no
NM_CONTROLLED=no
VLAN=yes
TYPE=Ethernet
OES
      )
    end
  end

  context 'vlan100' do
    let(:title) { 'vlan100' }
    let(:params) do
      {
          ipaddress: %w{10.0.0.1/24},
          config_dir: '/etc/sysconfig/network-scripts',
          parent: :bond0,
          type: :vlan,
          vlanid: 100,
      }
    end

    it 'should contain ifcfg-vlan100' do
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-vlan100').with_content(<<-OES
#
# Managed by Puppet in the sandbox environment
#
BOOTPROTO=none
DEVICE=vlan100
IPADDR=10.0.0.1
PREFIX=24
ONBOOT=yes
USERCTL=no
NM_CONTROLLED=no
VLAN=yes
TYPE=Ethernet
PHYSDEV=bond0
OES
      )
    end
  end

  context 'lo' do
    let(:title) { 'lo' }
    let(:params) do
      {
          ipaddress: %w{127.0.0.1/8 10.0.0.1/32},
          config_dir: '/etc/sysconfig/network-scripts',
          type: :loopback,
      }
    end

    it 'should contain ifcfg-lo' do
      is_expected.to contain_file('/etc/sysconfig/network-scripts/ifcfg-lo').with_content(<<-OES
#
# Managed by Puppet in the sandbox environment
#
BOOTPROTO=none
DEVICE=lo
IPADDR=127.0.0.1
PREFIX=8
IPADDR1=10.0.0.1
PREFIX1=32
ONBOOT=yes
USERCTL=no
NM_CONTROLLED=no
OES
      )
    end
  end
end
