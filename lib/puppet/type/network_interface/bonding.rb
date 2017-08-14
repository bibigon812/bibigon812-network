require 'puppet/util/bibigon812/network'

Puppet::Type.type(:network_interface).newproperty(:lacp_rate) do
  desc %q{
    Option specifying the rate in which we'll ask our link partner to transmit
    LACPDU packets in 802.3ad mode.
  }

  defaultto(:slow)
  newvalues(:slow, :fast)
end

Puppet::Type.type(:network_interface).newproperty(:miimon) do
  desc 'Specifies the MII link monitoring frequency in milliseconds.'

  defaultto(100)
  newvalues(/\A\d+\Z/)
end

Puppet::Type.type(:network_interface).newproperty(:bond_mode) do
  desc 'Specifies one of the bonding policies.'

  defaultto('802.3ad')
  newvalues('balance-rr', 'active-backup', 'balance-xor', 'broadcast', '802.3ad', 'balance-tlb', 'balance-alb')
end

Puppet::Type.type(:network_interface).newproperty(:bond_slaves, array_matching: :all) do
  desc 'Specifies a list of the bonding slaves.'

  defaultto([])

  validate do |value|
    unless Puppet::Util::Network::Bondable.include? Puppet::Util::Network::get_interface_type(value)
      fail 'Invalid value. The interface %{value} cannot be a bond slave.' % {value: value}
    end
  end

  def insync?(is)
    is.each do |value|
      return false unless @should.include?(value)
    end

    @should.each do |value|
      return false unless is.include?(value)
    end

    true
  end
end

Puppet::Type.type(:network_interface).newproperty(:xmit_hash_policy) do
  desc 'This policy uses upper layer protocol information, when available, to generate the hash.'

  defaultto('layer3+4')
  newvalues('layer2', 'layer3+4')
end
