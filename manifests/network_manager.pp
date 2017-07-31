#
#
#
class network::network_manager (
  Boolean $enable,
  Enum['running', 'stopped', 'masked'] $ensure,
) {

  service { 'NetworkManager':
    ensure => $ensure,
    enable => $enable,
  }

}