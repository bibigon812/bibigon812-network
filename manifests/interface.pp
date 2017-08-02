#
# Authors
# -------
#
# Dmitriy Yakovlev <yak0vl3v@gmail.com>
#
# Copyright
# ---------
#
# Copyright 2017 Dmitriy Yakovlev, unless otherwise noted.
#
define network::interface (
  Enum['absent', 'present']
  $ensure = 'present',

  Optional[Enum['bond', 'hw', 'loopback', 'vlan']]
  $type = undef,

  Optional[Enum['fast', 'slow']]
  $bond_lacp_rate = undef,

  Optional[Integer[0,1000]]
  $bond_miimon = undef,

  Optional[Enum['balance-rr', 'active-backup', 'balance-xor', 'broadcast', '802.3ad', 'balance-tlb', 'balance-alb']]
  $bond_mode = undef,

  Optional[Variant[Array[String], String]]
  $bond_slaves = undef,

  Optional[Enum['layer2', 'layer3+4']]
  $bond_xmit_hash_policy = undef,

  Optional[Variant[Array[String], String]]
  $ipaddress = undef,

  Optional[String]
  $mac = undef,

  Optional[String]
  $master = undef,

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
      default => any2array($bond_slaves),
    }

    $real_bond_xmit_hash_policy = $bond_xmit_hash_policy ? {
      undef   => 'layer3+4',
      default => $bond_xmit_hash_policy,
    }

    $real_vlanid = undef

  } elsif $real_type == 'vlan' {
    $real_bond_lacp_rate = undef
    $real_bond_miimon = undef
    $real_bond_mode = undef
    $real_bond_slaves = undef
    $real_bond_xmit_hash_policy = undef
    $real_vlanid = $vlanid ? {
      undef   => 0 + $name.match(/\A(\w+\.|vlan)(\d+)\Z/)[2],
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

  $pre_ipaddress = $ipaddress ? {
    undef   => [],
    default => any2array($ipaddress),
  }

  # Add the default ip of the loopback interface if it's absent
  if $real_type == 'loopback' {
    if ! ('127.0.0.1/8' in $pre_ipaddress) {
      $real_ipaddress = concat(['127.0.0.1/8'], $pre_ipaddress)
    }
  } else {
    $real_ipaddress = $pre_ipaddress
  }

  # Create the resource type
  network_interface {$name:
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
  }

  # Create configuration files
  network::interface::config {$name:
    ensure                => $ensure,
    type                  => $real_type,
    bond_lacp_rate        => $real_bond_lacp_rate,
    bond_miimon           => $real_bond_miimon,
    bond_mode             => $real_bond_mode,
    bond_slaves           => $real_bond_slaves,
    bond_xmit_hash_policy => $real_bond_xmit_hash_policy,
    ipaddress             => $real_ipaddress,
    mac                   => $mac,
    master                => $master,
    mtu                   => $mtu,
    parent                => $parent,
    state                 => $state,
    vlanid                => $real_vlanid,
    require               => Network_interface[$name],
  }
}