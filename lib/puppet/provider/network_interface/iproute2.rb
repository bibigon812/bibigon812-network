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

  def initialize(value = {})
    super(value)
    @state_hash = {}  # interface_name => :up or :down
  end


  def self.instances
    providers = []

    hash = {}

    ip('addr').split(/\n/).collect do |line|
      # Find a new interface
      if /\A\d+:\s(\S+):\s<[A-Z,_]+>\smtu\s(\d+)\sqdisc\s(\S+)\sstate\s(\S+)/ =~ line
        name_and_parent = $1
        mtu = Integer($2)
        state = parse_state($4)

        name, parent = name_and_parent.split('@')

        type = parse_interface_type(name)

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

        # Add default values
        @resource_map.each do |property, options|
          next unless options.has_key?(:default)
          if options[:type] == :array or options[:type] == :hash
            hash[property] = options[:default].clone
          else
            hash[property] = options[:default]
          end
        end

        # Add bond options
        if type == :bond
          @bond_options_map.each do |bond_option, file|
            if bond_option == :bond_miimon
              hash[bond_option] = Integer(File.read("/sys/class/net/#{name}/bonding/#{file}"))
            else
              hash[bond_option] = File.read("/sys/class/net/#{name}/bonding/#{file}").split(/\s/).first
            end
          end

          hash[:bond_slaves] = get_bond_slaves(name)

        # Add vlan options
        elsif type == :vlan
          hash[:tag] = parse_vlan_tag(name)
        end

        hash[:parent] = parent unless parent.nil? or parent == 'NONE'

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


  def self.bond_exists?(bond)
    File.directory?("/sys/class/net/#{bond}/bonding")
  end


  def self.get_bond_slaves(bond)
    if bond_exists?(bond)
      File.read("/sys/class/net/#{bond}/bonding/slaves").split(/\s/)
    else
      []
    end
  end


  def self.parse_interface_type(name)
    if name.include?('.') or name.include?('vlan')
      :vlan
    elsif name.include?('bond')
      :bond
    else
      :hw
    end
  end


  def self.parse_vlan_tag(name)
    if name.include?('vlan')
      Integer(resource[:name].sub(/\Avlan/, ''))
    else
      Integer(name.split('.').last)
    end
  end


  def self.parse_state(value)
    case value
      when 'UP'
        :up
      when 'DOWN'
        :down
      else
        :unknown
    end
  end


  def create
    # Don't create hardware interface
    if @resource[:type] == :hw
      debug 'Can not create the hardware interface.'
      return
    end

    debug 'Creating the %{name} interface' % { name: @resource[:name] }

    @property_hash[:name] = @resource[:name]
    @property_hash[:ensure] = :present
    self.type = @resource[:type]

    if @resource[:type] == :vlan
      self.parent = @resource[:parent]
      self.tag = @resource[:tag]

    elsif @resource[:type] == :bond
      # Insert the kernel module `bonding`
      unless File.exists?('/sys/class/net/bonding_masters')
        modprobe(['bonding',])

        # Remove the default bond interfaces
        begin
          File.read('/sys/class/net/bonding_masters').split(/\s/).each do |bond|
            File.write('/sys/class/net/bonding_masters', "-#{bond}")
          end
        rescue Exception => e
          notice e.message
        end
      end

      # Create a bond interface
      File.write('/sys/class/net/bonding_masters', "+#{@resource[:name]}")

      self.bond_lacp_rate        = @resource[:bond_lacp_rate]
      self.bond_miimon           = @resource[:bond_miimon]
      self.bond_mode             = @resource[:bond_mode]
      self.bond_xmit_hash_policy = @resource[:bond_xmit_hash_policy]
      self.bond_slaves           = @resource[:bond_slaves]
    end

    self.ipaddress = @resource[:ipaddress]
    self.mtu       = @resource[:mtu]
    self.mac       = @resource[:mac]
    self.state     = @resource[:state]
  end


  def destroy
    debug 'Shutdown the interface %{name}.' % { name: @property_hash[:name] }

    self.state = :down

    if @property_hash[:type] == :bond
      debug 'Destroy the interface %{name}.' % { name: @property_hash[:name] }

      # Remove slaves
      delete_bond_slaves(@property_hash[:name], @property_hash[:bond_slaves])
      ip(['link', 'delete', 'dev', @property_hash[:name], 'type', 'bond'])

    elsif @property_hash[:type] == :vlan
      debug 'Destroy the interface %{name}.' % { name: @property_hash[:name] }
      ip(['link', 'delete', 'dev', @property_hash[:name], 'type', 'vlan'])

    else
      debug 'Can not destroy the hardware interface \'%{name}\'.' % { name: @property_hash[:name] }
    end

    @property_hash.clear
  end


  def exists?
    @property_hash[:ensure] == :present
  end

  def ipaddress
    @property_hash[:ipaddress] || []
  end

  def ipaddress=(value)
    @property_hash[:ipaddress] ||= []

    (value - @property_hash[:ipaddress]).each do |ipaddress|
      ip(['address', 'add', ipaddress, 'dev', @property_hash[:name]])
    end

    (@property_hash[:ipaddress] - value).each do |ipaddress|
      ip(['address', 'delete', ipaddress, 'dev', @property_hash[:name]])
    end

    @property_hash[:ipaddress] = value
  end

  def mac
    @property_hash[:mac] || :absent
  end

  def mac=(value)
    ip(['link', 'set', 'dev', @property_hash[:name], 'address', value])
    @property_hash[:mac] = value
  end

  def mtu
    @property_hash[:mtu] || :absent
  end

  def mtu=(value)
    ip(['link', 'set', 'dev', @property_hash[:name], 'mtu', value.to_s])
    @property_hash[:mtu] = value
  end

  def parent
    @property_hash[:parent] || :absent
  end

  def parent=(value)
    @property_hash[:parent] = value
  end

  def state
    @property_hash[:state] || :absent
  end

  def state=(value)
    ip(['link', 'set', 'dev', @property_hash[:name], value.to_s]) unless value == :unknown
    @property_hash[:state] = value
  end

  def type
    @property_hash[:type] || :absent
  end

  def type=(value)
    @property_hash[:type] = value
  end

  def bond_lacp_rate
    @property_hash[:bond_lacp_rate] || :absent
  end

  def bond_lacp_rate=(value)
    begin
      File.write("/sys/class/net/#{@property_hash[:name]}/bonding/lacp_rate", value.to_s)
    rescue Exception => e
      notice e.message
    end

    @property_hash[:bond_lacp_rate] = value
  end

  def bond_miimon
    @property_hash[:bond_miimon] || :absent
  end

  def bond_miimon=(value)
    begin
      File.write("/sys/class/net/#{@property_hash[:name]}/bonding/miimon", value.to_s)
    rescue Exception => e
      notice e.message
    end

    @property_hash[:bond_miimon] = value
  end

  def bond_mode
    @property_hash[:bond_mode] || :absent
  end

  def bond_mode=(value)
    begin
      File.write("/sys/class/net/#{@property_hash[:name]}/bonding/mode", value.to_s)
    rescue Exception => e
      notice e.message
    end

    @property_hash[:bond_mode] = value
  end

  def bond_slaves
    @property_hash[:bond_slaves] || []
  end

  def bond_slaves=(value)
    @property_hash[:bond_slaves] ||= []
    sync_bond_slaves(@property_hash[:name], @property_hash[:bond_slaves], value)
    @property_hash[:bond_slaves] = value
  end

  def bond_xmit_hash_policy
    @property_hash[:bond_xmit_hash_policy] || :absent
  end

  def bond_xmit_hash_policy=(value)
    begin
      File.write("/sys/class/net/#{@property_hash[:name]}/bonding/xmit_hash_policy", value.to_s)
    rescue Exception => e
      e.message
    end

    @property_hash[:bond_xmit_hash_policy] = value
  end

  def tag
    @property_hash[:tag] || :absent
  end

  def tag=(value)
    ip(['link', 'add', 'name', @property_hash[:name], 'link', @property_hash[:parent], 'type', 'vlan', 'id', value.to_s])
    @property_hash[:tag] = value
  end


  private
  def add
    :add
  end


  def delete
    :delete
  end


  def add_bond_slaves(bond, slaves)
    manage_bond_slaves(bond, slaves, add) unless slaves.empty?
  end


  def delete_bond_slaves(bond, slaves)
    manage_bond_slaves(bond, slaves, delete) unless slaves.empty?
  end


  def bond_exists?(name)
    File.directory?("/sys/class/net/#{name}/bonding")
  end


  def interface_exists?(name)
    File.directory?("/sys/class/net/#{name}")
  end


  def get_state(name)
    @state_hash[name] ||=
        begin
          File.read("/sys/class/net/#{name}/operstate").to_sym
        rescue Exception =>  e
          notice e.message
          :unknown
        end

    @state_hash[name]
  end


  def sync_bond_slaves(bond, is, should)
    add_bond_slaves(bond, should - is)
    delete_bond_slaves(bond, is - should)
  end


  def manage_bond_slaves(bond, slaves, command = add)
    # Exit if no bond interface
    return unless bond_exists?(bond)

    prefix = command == :delete ? '-' : '+'

    slaves.each do |slave|
      next unless interface_exists?(slave) and self.class.parse_interface_type(slave) == :hw

      ip(['link', 'set', 'dev', slave, 'down']) if get_state(slave) == :up
      begin
        File.write("/sys/class/net/#{bond}/bonding/slaves", "#{prefix}#{slave}")
      rescue Exception => e
        notice e.message
      end
      ip(['link', 'set', 'dev', slave, 'up']) if get_state(slave) == :up
    end
  end
end