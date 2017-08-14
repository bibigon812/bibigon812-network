require 'puppet/util/network'

Puppet::Type.type(:network_interface).autorequire(:network_interface) do

  reqs = []

  reqs << self[:parent] unless self[:parent].nil?

  self[:bond_slaves].each do |slave|
    reqs << slave
  end

  reqs
end
