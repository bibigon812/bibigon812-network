Puppet::Type.type(:network_interface).provide(:iproute2) do
  @doc = 'Manages network interface parameters'

  confine exists: '/usr/sbin/ip'

  commands cat: 'cat', echo: 'echo', ip: 'ip', modprobe: 'modprobe'


  @resource_map = {
      ipaddress: {
          default: [],
          regexp: /\A\s+inet\s(\S+)\s/,
          type: :array,
      },
      mac: {
          regexp: /\A\s+link\/ether\s(\S+)\s/,
          type: :string,
      }
  }

  def self.instances
    providers = []

    hash = {}

    ip('addr').split(/\n/).collect do |line|
      # Find a new interface
      if /\A\d+:\s(\S+):\s<[A-Z,_]+>\smtu\s(\d+)\sqdisc\s(\S+)\sstate\s(\S+)/ =~ line
        name_and_parent = $1
        mtu = Integer($2)
        state = case $4
                  when 'UNKNOWN', 'UP'
                    :enabled
                  when 'DOWN'
                    :disabled
                  else
                    :absent
                end

        name, parent = name_and_parent.split('@')

        type = if name.include?('.') or name.include?('vlan')
                 :vlan
               elsif name.include?('bond')
                 :bond
               else
                 :eth
               end

        # Add hash to providers
        unless hash.empty?
          debug 'Instantiated the interface: %{name}.' % { name: hash[:name] }
          providers << new(hash)
        end

        hash = {
            ensure: state,
            mtu: mtu,
            name: name.split(/@/).first,
            provider: self.name,
            type: type,
        }

        if type == :bond
          hash[:bond_lacp_rate] = cat("/sys/class/net/#{name}/bonding/lacp_rate").split(/\s/).first
          hash[:bond_miimon] = Integer(cat("/sys/class/net/#{name}/bonding/miimon"))
          hash[:bond_mode] = cat("/sys/class/net/#{name}/bonding/mode").split(/\s/).first
          hash[:bond_xmit_hash_policy] = cat("/sys/class/net/#{name}/bonding/xmit_hash_policy").split(/\s/).first
        end

        hash[:parent] = parent unless parent.nil? or parent == 'NONE'

        # Add default values
        @resource_map.each do |property, options|
          next unless options.has_key?(:default)
          if options[:type] == :array or options[:type] == :hash
            hash[property] = options[:default].clone
          else
            hash[property] = options[:default]
          end
        end

      # Parse interface properties
      else
        @resource_map.each do |property, options|
          if options[:regexp] =~ line
            value = $1
            if value.nil?
              hash[property] = :true if options[:type] == :boolean
            else
              case options[:type]
                when :array
                  hash[property] << value

                when :fixnum
                  hash[property] = value.to_i

                when :boolean
                  hash[property] = :true

                else
                  hash[property] = value
              end
            end
          end
        end
      end
    end

    unless hash.empty?
      debug 'Instantiated the interface: %{name}.' % { name: hash[:name] }
      providers << new(hash)
    end

    providers
  end

  def self.prefetch(resources)
    debug 'Prefetch resources'
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find{ |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    debug 'Enabling the %{name} interface' % { name: @resource[:mtu] }

    if @resource[:type] == :vlan
      ip(['link', 'add', 'name', @resource[:name], 'link', @resource[:parent], 'type', 'vlan', 'id', @resource[:tag].to_s])
    elsif @resource[:type] == :bond
      modprobe([
                   'bonding',
                   "mode=#{@resource[:bond_mode]}",
                   "miimon=#{@resource[:bond_miimon]}",
                   "lacp_rate=#{@resource[:bond_lacp_rate]}",
                   "xmit_hash_policy=#{@resource[:bind_xmit_hash_policy]}",
               ])
    end

    @resource[:ipaddress].each do |ipaddress|
      ip(['addr', 'add', ipaddress, 'dev', @resource[:name]])
    end

    ip(['link', 'set', 'dev', @resource[:name], 'mtu', @resource[:mtu].to_s])
    ip(['link', 'set', 'dev', @resource[:name], 'address', @resource[:mac]])
    ip(['link', 'set', 'dev', @resource[:name], 'up'])
  end
end