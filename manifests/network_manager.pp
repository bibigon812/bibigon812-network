#
#
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