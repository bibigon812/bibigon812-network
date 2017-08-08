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
# Hash of network interface parameters. Defaults to `{}`.
#
# * `routes`
# Hash of route parameters. Defaults to `{}`.
#
# Examples
# --------
#
# @example
#    class { 'network':
#      interface_config_dir => '/etc/sysconfig/network-scripts',
#      interfaces           => {
#        lo      => {
#          ipaddress => [
#            '10.0.0.1/32',
#            '10.255.255.1/32',
#          ],
#        },
#        bond0   => {
#          bond_slaves => [
#            eth0,
#            eth1,
#          ],
#        },
#        vlan100 => {
#          ipaddress => [
#            '192.168.1.1/24',
#            '192.168.2.1/24',
#          ],
#          parent    => 'bond0',
#        },
#      },
#      routes               => {
#        '192.168.0.0/24' => {
#          device  => 'vlan100',
#          nexthop => '192.168.1.100',
#        },
#        '172.16.0.0/24'  => {
#          device  => 'vlan100',
#          nexthop => '192.168.1.100',
#        },
#        '172.16.0.0/24'  => {
#          device  => 'vlan100',
#          metric  => 100,
#          nexthop => '192.168.1.200',
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
  $config_dir,

  Hash
  $interfaces,

  Hash
  $routes,
) {

  contain network::network_manager

  Network::Interface::Config {
    config_dir => $config_dir,
  }

  # Find bond_slaves and add master to them
  merge($interfaces,
    $interfaces.reduce({}) |Hash $slaves, Tuple[String, Hash] $value| {
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

  $routes.each |String $route_name, Hash $route_params| {
    network_route {$route_name:
      * => $route_params,
    }
  }

  Network::Interface::Routes::Config {
    config_dir => $config_dir,
  }

  # Prepare the hash for route files
  $routes.reduce({}) |Hash $route_devices, Tuple[String, Hash] $value| {
    $prefix = split($value[0], /\s+/)[0]
    merge($route_devices, { $value[1]['device'] => deep_merge({ routes => [ merge($value[1], { prefix => $prefix }) ] }) })
  }.each |String $device, Hash $routes| {
    network::interface::routes::config {$device:
      *       => $routes,
      require => Network::Interface::Config[$device],
    }
  }
}
