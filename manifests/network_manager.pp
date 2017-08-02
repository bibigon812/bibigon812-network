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
class network::network_manager (
  Boolean $enable,
  Enum['running', 'stopped'] $ensure,
) {
  service { 'NetworkManager':
    ensure => $ensure,
    enable => $enable,
  }
}