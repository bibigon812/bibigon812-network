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
define network::interface::routes::config (
  String
  $config_dir,

  Array
  $routes,

  Enum['absent', 'present']
  $ensure = 'present',

) {

  $env = $::environment

  file {"${config_dir}/route-${name}":
    ensure  => $ensure,
    content => template("network/${facts['os']['family']}/route.erb"),
  }
}