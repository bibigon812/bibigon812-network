# Class: network
# ===========================
#
# Full description of class network here.
#
# Parameters
# ----------
#
# Document parameters here.
#
# * `sample parameter`
# Explanation of what this parameter affects and what it defaults to.
# e.g. "Specify one or more upstream ntp servers as an array."
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
#
# @example
#    class { 'network':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
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
  String $interface_config_dir,
  Hash $interfaces,
) {

  contain network::network_manager

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
      *                    => $interface_params,
      interface_config_dir => $interface_config_dir,
    }
  }

}
