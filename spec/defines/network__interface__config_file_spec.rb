require 'spec_helper'

describe 'network::interface::config_file' do
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
          ipaddress: %w{10.0.0.1/24},
          interface_config_dir: '/etc/sysconfig/network-scripts',
          type: :hw,
      }
    end

    it do
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
  end

  context 'bond0' do
    let(:title) { 'bond0' }
    let(:params) do
      {
          bond_lacp_rate: :fast,
          bond_miimon: 100,
          bond_mode: '802.3ad',
          bond_slaves: [:eth1],
          bond_xmit_hash_policy: :layer2,
          ipaddress: %w{10.0.0.1/24},
          interface_config_dir: '/etc/sysconfig/network-scripts',
          type: :bond,
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
          interface_config_dir: '/etc/sysconfig/network-scripts',
          type: :vlan,
          vlanid: 100,
      }
    end

    it do
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

end