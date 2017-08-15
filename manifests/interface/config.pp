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
define network::interface::config (
  String
  $config_dir,

  Enum['absent', 'present']
  $ensure = 'present',

  Enum['down', 'up']
  $state = 'up',

  Array
  $routes = [],

  Optional[Enum['bond', 'hw', 'loopback', 'vlan']]
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

  Optional[String]
  $master = undef,

  Optional[Integer[1,9000]]
  $mtu = undef,

  Optional[String]
  $parent = undef,

  Optional[Integer[1,4095]]
  $vlanid = undef,
) {

  $env = $::environment
  $interface_name = $name

  # Add interface configs
  file {"${config_dir}/ifcfg-${name}":
    ensure  => $ensure,
    content => template("network/${facts['os']['family']}/ifcfg.erb"),
  }

  # Add routes config
  if empty($routes) {
    file {"${config_dir}/route-${name}":
      ensure  => absent,
    }

  } else {
    file { "${config_dir}/route-${name}":
      ensure  => $ensure,
      content => template("network/${facts['os']['family']}/route.erb"),
    }
  }
}
