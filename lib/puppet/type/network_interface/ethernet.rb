require 'puppet/util/network'

Puppet::Type.type(:network_interface).newproperty(:mac) do
  desc 'Specifies a MAC address.'
  newvalues(/\A(\h\h(?::|-)?){5}\h\h\Z/)
end
