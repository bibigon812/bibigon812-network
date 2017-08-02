# Class: network
# ===========================
#
# This class manages network interfaces.
#
# Parameters
# ----------
#
# * `interface_config_dir`
# CentOs => '/etc/sysconfig/network-scripts'
#
# * `interfaces`
# Hash of network interface parameters. Defaults to `{}`
#
# Examples
# --------
#
# @example
#    class { 'network':
#      interface_config_dir => '/etc/sysconfig/network-scripts',
#      interfaces => {
#        lo => {
#          ipaddress => [
#            '10.0.0.1/32',
#            '10.255.255.1/32',
#          ],
#        },
#        bond0 => {
#          bond_slaves => [
#            eth0,
#            eth1,
#          ],
#        },
#        bond0.100 => {
#          ipaddress => [
#            '192.168.1.1/24',
#            '192.168.2.1/24',
#          ],
#        },
#      },
#    }
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
class network (
  String
  $interface_config_dir,

  Hash
  $interfaces,
) {

  contain network::network_manager

  Network::Interface::Config {
    interface_config_dir => $interface_config_dir,
  }

  # Find bond_slaves and add master to them
  merge($interfaces,
    $interfaces.reduce({}) |Hash $slaves, Tuple[String, Hash]$value| {
      $interface_name = $value[0]
      if $value[1]['bond_slaves'] {
        merge($slaves, any2array($value[1]['bond_slaves']).reduce({}) |Hash $memo, String $value| {
          merge($memo, { $value => { master => $interface_name } })
        })
      } else {
        $slaves
      }
    }
  ).each |String $interface_name, Hash $interface_params| {
    network::interface {$interface_name:
      * => $interface_params,
    }
  }
}
