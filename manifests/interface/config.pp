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
  $interface_config_dir,

  Enum['absent', 'present']
  $ensure = 'present',

  Enum['down', 'up']
  $state = 'up',

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

  if empty($ipaddress) {
    $ipaddr = undef
    $prefix = undef
  } else {
    $ipaddr_prefix = split($ipaddress[0], '/')
    $ipaddr = $ipaddr_prefix[0]
    $prefix = $ipaddr_prefix[1]

    # Add alias configs
    $ipaddress[1,-1].reduce({}) |Hash $memo, String $value| {
      if empty($memo) {
        $index = 1
      } else {
        $index = keys($memo)[-1] + 1
      }
      $ipaddr_prefix = split($value, '/')
      $ipaddr = $ipaddr_prefix[0]
      $prefix = $ipaddr_prefix[1]
      merge($memo, { $index => { ipaddr => $ipaddr, prefix => $prefix } })
    }.each |Integer $index, Hash $ipaddress| {
      $ipaddr = $ipaddress['ipaddr']
      $prefix = $ipaddress['prefix']

      file {"${interface_config_dir}/ifcfg-${name}:${index}":
        ensure  => $ensure,
        content => template("network/${facts['os']['family']}/ifcfg-alias.erb"),
      }
    }
  }

  # Add interface configs
  file {"${interface_config_dir}/ifcfg-${name}":
    ensure  => $ensure,
    content => template("network/${facts['os']['family']}/ifcfg.erb"),
  }

}