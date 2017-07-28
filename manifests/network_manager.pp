class network::network_manager (
  Enum['running', 'stopped', 'masked'] $ensure,
  Boolean $enable,
) {

  service { 'NetworkManager':
    ensure => $ensure,
    enable => $enable,
  }

}