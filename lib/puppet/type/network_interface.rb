Puppet::Type.newtype(:network_interface) do
  @doc = 'This type provides the capabilities to manage network interface paramaters'

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'Interface name.'
    newvalues(/\Abond\d+(\.\d+)?\Z/)
    newvalues(/\Avlan\d+\Z/)
    newvalues(/\A[[:alpha:]]+\w+(\.\d+)?\Z/)
  end

  newparam(:type) do
    desc 'Type of this interface.'

    newvalues(:bond, :hw, :loopback, :vlan)
    defaultto {
      if resource[:name] == 'lo'
        :loopback
      elsif resource[:name].include?('.') or resource[:name].include?('vlan')
        :vlan
      elsif resource[:name].include?('bond')
        :bond
      else
        :hw
      end
    }
  end

  newproperty(:bond_lacp_rate) do
    desc %q{Option specifying the rate in which we'll ask our link partner to transmit LACPDU packets in 802.3ad mode.}

    newvalues(:slow, :fast)
    defaultto :slow
  end

  newproperty(:bond_miimon) do
    desc 'Specifies the MII link monitoring frequency in milliseconds.'

    defaultto 100

    validate do |value|
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 0-1000.' % { value: value } unless value >= 0 and value <= 1000
    end
  end

  newproperty(:bond_mode) do
    desc 'Specifies one of the bonding policies.'

    newvalues('balance-rr', 'active-backup', 'balance-xor', 'broadcast', '802.3ad', 'balance-tlb', 'balance-alb')
    defaultto '802.3ad'
  end

  newproperty(:bond_slaves, array_matching: :all) do
    desc 'Specifies a list of the bonding slaves.'
    defaultto []
  end

  newproperty(:bond_xmit_hash_policy) do
    desc 'This policy uses upper layer protocol information, when available, to generate the hash.'

    newvalues('layer2', 'layer3+4')
    defaultto 'layer3+4'
  end

  newproperty(:ipaddress, array_matching: :all) do
    desc 'Specifies a list of IP addresses.'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        fail 'Invalid value \'%{value}\'. It is not a IP address.' % { value: value }
      end
      fail 'Invalid value \'%{value}\'. Prefix length is not specified.' % {value: value } unless value.include?('/')
    end
  end

  newproperty(:mac) do
    desc 'Specifies a MAC address.'

    newvalues(/\A(\h\h(?::|-)?){5}\h\h\Z/)
  end

  newproperty(:mtu) do
    desc 'Specifies the maximum transmission unit.'
    defaultto 1500

    validate do |value|
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 1500-9000.' % { value: value } unless value >= 1500 and value <= 9000
    end
  end

  newproperty(:parent) do
    desc 'Specifies a parent interface.'
    defaultto {
      if resource[:name].include?('.')
        resource[:name].split('.').first
      else
        nil
      end
    }

    validate do |value|
      type =
          if resource[:name].include?('.') or resource[:name].include?('vlan')
            :vlan
          elsif resource[:name].include?('bond')
            :bond
          else
            :eth
          end

      fail 'Invalid value \'%{value}\'. This interface type does not support parent interface.' % { value: value } if type == :eth
    end
  end

  newproperty(:state) do
    desc 'State of this interface.'
    newvalues(:up, :down, :unknown)
    defaultto { resource[:name] == 'lo' ? :unknown : :up }
  end

  newproperty(:tag) do
    desc 'Vlan ID.'

    defaultto {
      begin
        if resource[:name].include?('.')
          Integer(resource[:name].split('.').last)
        elsif resource[:name].include?('vlan')
          Integer(resource[:name].sub(/\Avlan/, ''))
        else
          nil
        end
      rescue
        nil
      end
    }

    validate do |value|
      type =
          if resource[:name].include?('.') or resource[:name].include?('vlan')
            :vlan
          elsif resource[:name].include?('bond')
            :bond
          else
            :eth
          end

      fail 'Invalid value \'%{value}\'. This interface type does not support tagging.' % { value: value } unless type == :vlan
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 1-4095.' % { value: value } unless value >= 1 and value <= 4095
    end
  end

  autorequire(:network_interface) do
    reqs = []

    reqs += self[:bond_slaves] if self[:type]
    reqs << self[:parent] if self[:parent]

    reqs
  end
end