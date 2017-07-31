#
#
#
define network::interface (
  Enum['absent', 'present']
  $ensure = 'present',

  Optional[Enum['bond', 'hw', 'vlan']]
  $type = undef,

  Optional[Enum['fast', 'slow']]
  $bond_lacp_rate = undef,

  Optional[Integer[0,1000]]
  $bond_miimon = undef,

  Optional[Enum['balance-rr', 'active-backup', 'balance-xor', 'broadcast', '802.3ad', 'balance-tlb', 'balance-alb']]
  $bond_mode = undef,

  Optional[Array[String]]
  $bond_slaves = undef,

  Optional[Enum['layer2', 'layer3+4']]
  $bond_xmit_hash_policy = undef,

  Optional[Array[String]]
  $ipaddress = undef,

  Optional[String]
  $mac = undef,

  Optional[Integer[1,9000]]
  $mtu = undef,

  Optional[String]
  $parent = undef,

  Enum['down', 'up']
  $state = 'up',

  Optional[Integer[1,4095]]
  $vlanid = undef,
) {

  network_interface {$name:
    ensure                => $ensure,
    type                  => $type,
    bond_lacp_rate        => $bond_lacp_rate,
    bond_miimon           => $bond_miimon,
    bond_mode             => $bond_mode,
    bond_slaves           => $bond_slaves,
    bond_xmit_hash_policy => $bond_xmit_hash_policy,
    ipaddress             => $ipaddress,
    mac                   => $mac,
    mtu                   => $mtu,
    parent                => $parent,
    state                 => $state,
    vlanid                => $vlanid,
  }

  network::interface::config_file {"/etc/sysconfig/network-scripts/ifcfg-${name}":
    ensure                => Network_interface[$name]['ensure'],
    type                  => Network_interface[$name]['type'],
    bond_lacp_rate        => Network_interface[$name]['bond_lacp_rate'],
    bond_miimon           => Network_interface[$name]['bond_miimon'],
    bond_mode             => Network_interface[$name]['bond_mode'],
    bond_slaves           => Network_interface[$name]['bond_slaves'],
    bond_xmit_hash_policy => Network_interface[$name]['bond_xmit_hash_policy'],
    ipaddress             => Network_interface[$name]['ipaddress'],
    mac                   => Network_interface[$name]['mac'],
    mtu                   => Network_interface[$name]['mtu'],
    parent                => Network_interface[$name]['parent'],
    state                 => Network_interface[$name]['state'],
    vlanid                => Network_interface[$name]['vlanid'],
    subscribe             => Network_interface[$name],
  }

}