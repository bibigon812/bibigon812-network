Puppet::Type.newtype(:network_interface) do
  @doc = 'This type provides the capabilities to manage network interface paramaters'

  ensurable do
    newvalue(:absent) do
      provider.destroy
    end

    newvalue(:disabled, event: :interface_disabled) do
      provider.disable
    end

    newvalue(:enabled, event: :interface_enabled) do
      provider.enable
    end

    aliasvalue(:present, :enabled)

    defaultto { :enabled }

    def retrieve
      provider.state
    end
  end

  newparam(:name, namevar: true) do
    desc 'Interface name.'
  end

  newproperty(:ipaddress, array_matching: :all) do
    desc 'IP addresses'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        fail 'Invalid value \'%{value}\'. It is not a IP address' % { value: value }
      end
      fail 'Invalid value \'%{value}\'. Prefix length is not specified.' unless value.include?('/')
    end
  end
end