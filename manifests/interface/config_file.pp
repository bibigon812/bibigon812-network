define network::interface::config_file (
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

  String
  $interface_config_dir,
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
  }

  file {"${interface_config_dir}/ifcfg-${name}":
    content => template("network/${facts['os']['family']}/ifcfg.erb"),
  }

}