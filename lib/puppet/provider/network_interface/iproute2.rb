Puppet::Type.type(:network_interface).provide(:iproute2) do
  @doc = 'Manages network interface parameters'

  confine exists: '/usr/sbin/ip'

  commands ip: 'ip', modprobe: 'modprobe'


  @resource_map = {
      ipaddress: {
          default: [],
          regexp:  /\A\s+inet\s(\S+)\s/,
          type:    :array,
      },
      mac: {
          regexp:  /\A\s+link\/ether\s(\S+)\s/,
          type:    :string,
      }
  }

  @bond_options_map = {
        bond_lacp_rate:        'lacp_rate',
        bond_miimon:           'miimon',
        bond_mode:             'mode',
        bond_xmit_hash_policy: 'xmit_hash_policy',
  }

  def initialize(value={})
    super(value)
    @state_hash = {} # if_name => state
  end

  def self.instances
    providers = []

    hash = {}

    ip('addr').split(/\n/).collect do |line|
      # Find a new interface
      if /\A\d+:\s(\S+):\s<[A-Z,_]+>\smtu\s(\d+)\sqdisc\s(\S+)\sstate\s(\S+)/ =~ line
        name_and_parent = $1
        mtu = Integer($2)
        state = case $4
                  when 'UP'
                    :up
                  when 'DOWN'
                    :down
                  else
                    :unknown
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
            ensure:   :present,
            mtu:      mtu,
            name:     name,
            provider: self.name,
            state:    state,
            type:     type,
        }

        # Add bond options
        if type == :bond
          @bond_options_map.each do |bond_option, file|
            if bond_option == :bond_miimon
              hash[bond_option] = Integer(File.read("/sys/class/net/#{name}/bonding/#{file}"))
            else
              hash[bond_option] = File.read("/sys/class/net/#{name}/bonding/#{file}").split(/\s/).first
            end
          end
        elsif type == :vlan
          hash[:tag] =
              if name.include?('vlan')
                Integer(resource[:name].sub(/\Avlan/, ''))
              else
                Integer(name.split('.').last)
              end
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
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    debug 'Enabling the %{name} interface' % { name: @resource[:mtu] }

    bond_options_map = self.class.instance_variable_get('@bond_options_map')

    if @resource[:type] == :vlan
      ip(['link', 'add', 'name', @resource[:name], 'link', @resource[:parent], 'type', 'vlan', 'id', @resource[:tag].to_s])
    elsif @resource[:type] == :bond
      unless File.exists?('/sys/class/net/bonding_masters')
        modprobe(['bonding',])

        # Remove the default bond interfaces
        File.read('/sys/class/net/bonding_masters').split(/\s/).each do |bond|
          File.write('/sys/class/net/bonding_masters', "-#{bond}")
        end
      end

      bond_options_map.each do |bond_option, file|
        File.write("/sys/class/net/#{@resource[:name]}/bonding/#{file}", @resource[bond_option].to_s)
      end

      # Add bond slaves
      @resource[:bond_slaves].each do |slave|
        ip(['link', 'set', 'dev', slave, 'down']) if get_state(slave) == :up
        File.write("/sys/class/net/#{@resource[:name]}/bonding/slaves", "+#{slave}")
        ip(['link', 'set', 'dev', slave, 'up']) if get_state(slave) == :up
      end
    end

    @resource[:ipaddress].each do |ipaddress|
      ip(['addr', 'add', ipaddress, 'dev', @resource[:name]])
    end

    ip(['link', 'set', 'dev', @resource[:name], 'mtu', @resource[:mtu].to_s])
    ip(['link', 'set', 'dev', @resource[:name], 'address', @resource[:mac]])
    ip(['link', 'set', 'dev', @resource[:name], 'up'])
  end

  def destroy
    if @property_hash[:type] == :bond
    elsif @property_hash[:type] == :vlan

    end
  end

  private
  def get_state(name)
    @state_hash[name] ||=
        begin
          File.read("/sys/class/net/#{name}/operstate").to_sym
        rescue
          :unknown
        end

    @state_hash[name]
  end
end