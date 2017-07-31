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

  Variant[Array[String], String, Undef]
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

  $real_type = $type ? {
    undef   => $name ? {
      /\Abond\d+\Z/  => 'bond',
      /\Avlan\d+\Z/  => 'vlan',
      /\A\w+\.\d+\Z/ => 'vlan',
      /\Alo\Z/       => 'loopback',
      default        => 'hw',
    },
    default => $type,
  }

  if $real_type == 'bond' {
    $real_bond_lacp_rate = $bond_lacp_rate ? {
      undef   => 'slow',
      default => $bond_lacp_rate,
    }

    $real_bond_miimon = $bond_miimon ? {
      undef   => 100,
      default => $bond_miimon,
    }

    $real_bond_mode = $bond_mode ? {
      undef   => '802.3ad',
      default => $bond_mode,
    }

    $real_bond_slaves = $bond_slaves ? {
      undef   => [],
      default => $bond_slaves,
    }

    $real_bond_xmit_hash_policy = $bond_xmit_hash_policy ? {
      undef   => 'layer3+4',
      default => $bond_xmit_hash_policy,
    }
  } elsif $real_type == 'vlan' {
    $real_vlanid = $vlanid ? {
      undef   => Integer($name.match(/\A(\w+\.|vlan)(\d+)\Z/)[2]),
      default => $vlanid,
    }
  } else {
    $real_bond_lacp_rate = undef
    $real_bond_miimon = undef
    $real_bond_mode = undef
    $real_bond_slaves = undef
    $real_bond_xmit_hash_policy = undef
    $real_vlanid = undef
  }

  $real_ipaddress = any2array($ipaddress)

  network_interface {$name:
    ensure                => $ensure,
    type                  => $real_type,
    bond_lacp_rate        => $real_bond_lacp_rate,
    bond_miimon           => $real_bond_miimon,
    bond_mode             => $real_bond_mode,
    bond_slaves           => $real_bond_slaves,
    bond_xmit_hash_policy => $real_bond_xmit_hash_policy,
    ipaddress             => $ipaddress,
    mac                   => $mac,
    mtu                   => $mtu,
    parent                => $parent,
    state                 => $state,
    vlanid                => $real_vlanid,
  }

  network::interface::config_file {$name:
    ensure                => $ensure,
    type                  => $real_type,
    bond_lacp_rate        => $real_bond_lacp_rate,
    bond_miimon           => $real_bond_miimon,
    bond_mode             => $real_bond_mode,
    bond_slaves           => $real_bond_slaves,
    bond_xmit_hash_policy => $real_bond_xmit_hash_policy,
    ipaddress             => $real_ipaddress,
    mac                   => $mac,
    mtu                   => $mtu,
    parent                => $parent,
    state                 => $state,
    vlanid                => $real_vlanid,
    subscribe             => Network_interface[$name],
  }

}