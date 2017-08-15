$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..",".."))
require 'puppet/util/network'

Puppet::Type.type(:network_interface).newproperty(:parent) do
  desc 'Specifies a parent interface.'

  validate do |value|
    unless Puppet::Util::Network::Vlanable.include? Puppet::Util::Network::get_interface_type(value)
      fail 'Invalid value. The interface \'%{value}\' cannot have vlan.' % {value: value}
    end
    if value.nil?
      fail 'Invalid value. The parent interface is not specified.'
    end
  end
end

Puppet::Type.type(:network_interface).newparam(:vlanid) do
  desc 'Contains a vlanid.'

  defaultto do
    if Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Vlan
      Integer(Puppet::Util::Network::Interfaces[:vlan][:name_regexp].match(resource[:name])[1])
    else
      nil
    end
  end

  validate do |value|
    unless Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Vlan
      fail 'The interface %{name} cannot have the vlanid.' % {name: resource[:name]}
    end

    fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % {value: value} unless value.is_a?(Integer)
    fail 'Invalid value \'%{value}\'. Valid values are 1-4095.' % {value: value} unless value >= 1 and value <= 4095
  end
end
