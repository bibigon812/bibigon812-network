$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..",".."))
require 'puppet/util/network'

Puppet::Type.type(:network_interface).provide(:iproute2) do
  @doc = 'Manages network interface parameters.'

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

  @bonding_opts = {
    bond_mode:             {
      file: :mode,
      type: :string,
      },
    bond_miimon:           {
      file: :miimon,
      type: :fixnum,
      },
    bond_lacp_rate:        {
      file: :lacp_rate,
      type: :symbol,
      },
    bond_xmit_hash_policy: {
      file: :xmit_hash_policy,
      type: :string,
      },
  }

  def initialize(value = {})
    super(value)
    @state_hash = {}  # interface_name => :up or :down
  end


  def self.instances
    providers = []

    hash = {}

    ip('address').split(/\n/).collect do |line|
      # Find a new interface
      if /\A(\d+):\s(\S+):\s<([A-Z\-_,]+)>\smtu\s(\d+)/ =~ line
        index = Integer($1)
        name_and_parent = $2
        flags = $3.split(',')
        mtu = Integer($4)
        state = get_state(flags)

        name, parent = name_and_parent.split('@')

        type = get_interface_type(name)

        # Add hash to providers
        unless hash.empty?
          debug 'Instantiated the %{name} interface with %{hash}.' % {
              name: hash[:name],
              hash: hash.inspect,
          }

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

        # Add bonding options
        if type == :bonding
          hash.merge!(instance_bond(name))

        # Add vlan options
        elsif type == :vlan
          hash.merge!(instance_vlan(name))
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
      debug 'Instantiated the %{name} interface with %{hash}.' % {
          name: hash[:name],
          hash: hash.inspect,
      }

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

  def self.get_interface_type(name)
    case name
    when /\Alo\Z/
      :loopback
    when /\Abond\d+?\Z/
      :bonding
    when /\Avlan\d+\Z/
      :vlan
    when /\A[[:alpha:]]*([[:alpha:]]\d+)+\Z/
      :ethernet
    else
      :unknown
    end
  end

  def self.get_state(flags)
    if flags.include?('UP')
      :up
    else
      :down
    end
  end

  def create
    # Don't create hardware interface
    if @resource[:type] == :ethernet
      notice 'Can not create the hardware interface.'
      return
    end

    debug 'Creating the %{name} interface with %{hash}.' % {
        name: @resource[:name],
        hash: @resource.to_hash.inspect
    }

    @property_hash[:name] = @resource[:name]
    @property_hash[:ensure] = :present
    self.type = @resource[:type]

    if @resource[:type] == :vlan
      create_vlan

    elsif @resource[:type] == :bonding
      create_bonding
    end

    self.ipaddress = @resource[:ipaddress]
    self.mtu       = @resource[:mtu]
    self.mac       = @resource[:mac]
    self.state     = @resource[:state]
  end

  def destroy
    return unless interface_exists?(@property_hash[:name])

    debug 'Shutdown the interface %{name}.' % { name: @property_hash[:name] }

    self.state = Puppet::Util::Network::Down

    if @property_hash[:type] == :bonding
      destroy_bonding

    elsif @property_hash[:type] == :vlan
      destroy_vlan

    else
      debug 'Can not destroy the interface \'%{name}\'.' % { name: @property_hash[:name] }
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
    (value - self.ipaddress).each do |ipaddress|
      ip(['address', 'add', ipaddress, 'dev', @property_hash[:name]])
    end

    (self.ipaddress - value).each do |ipaddress|
      ip(['address', 'delete', ipaddress, 'dev', @property_hash[:name]])
    end

    @property_hash[:ipaddress] = value
  end

  def mac
    @property_hash[:mac] || :absent
  end

  def mac=(value)
    return if value.nil?
    ip(['link', 'set', 'dev', @property_hash[:name], 'address', value])
    @property_hash[:mac] = value
  end

  def mtu
    @property_hash[:mtu] || :absent
  end

  def mtu=(value)
    return if value.nil?
    ip(['link', 'set', 'dev', @property_hash[:name], 'mtu', value.to_s])
    @property_hash[:mtu] = value
  end

  def state
    @property_hash[:state] || :down
  end

  def state=(value)
    if [:up, :down].include?(value)
      ip(['link', 'set', 'dev', @property_hash[:name], value.to_s])
    end

    @property_hash[:state] = value
  end

  def type
    @property_hash[:type] || :absent
  end

  def type=(value)
    @property_hash[:type] = value
  end


  ##
  ## Bonding
  ##

  def self.instance_bond(name)
    hash = {}

    @bonding_opts.each do |option_name, options|
      value = File.read("/sys/class/net/#{name}/bonding/#{options[:file]}").split(/\s+/).first
      case options[:type]
      when :fixnum
        hash[option_name] = Integer(value)
      when :symbol
        hash[option_name] = value.to_sym
      else
        hash[option_name] = value
      end
    end

    hash[:bond_slaves] = get_bond_slaves(name)

    hash
  end

  def self.interface_is_bonding?(bond)
    File.directory?("/sys/class/net/#{bond}/bonding")
  end

  def self.get_bond_slaves(bond)
    if interface_is_bonding?(bond)
      File.read("/sys/class/net/#{bond}/bonding/slaves").strip.split(/\s/)
    else
      []
    end
  end

  def create_bonding
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

    self.bond_mode             = @resource[:bond_mode]
    self.bond_miimon           = @resource[:bond_miimon]
    self.bond_lacp_rate        = @resource[:bond_lacp_rate]
    self.bond_xmit_hash_policy = @resource[:bond_xmit_hash_policy]
    self.bond_slaves           = @resource[:bond_slaves]
  end

  def destroy_bonding
    debug 'Remove bond slaves %{slaves}' % { slaves: self.bond_slaves.inspect }
    delete_slaves(@property_hash[:name], self.bond_slaves)

    debug 'Destroy the %{name} interface.' % { name: @property_hash[:name] }
    ip(['link', 'delete', 'dev', @property_hash[:name], 'type', 'bond'])
  end

  def bond_lacp_rate
    @property_hash[:lacp_rate] || :absent
  end

  def bond_lacp_rate=(value)
    return unless self.type == :bonding

    save_state_and_shutdown

    begin
      File.write("/sys/class/net/#{@property_hash[:name]}/bonding/lacp_rate", value.to_s)
    rescue Exception => e
      notice e.message
    end

    restore_state

    @property_hash[:lacp_rate] = value
  end

  def bond_miimon
    @property_hash[:miimon] || :absent
  end

  def bond_miimon=(value)
    return unless self.type == :bonding

    begin
      File.write("/sys/class/net/#{@property_hash[:name]}/bonding/miimon", value.to_s)
    rescue Exception => e
      notice e.message
    end

    @property_hash[:miimon] = value
  end

  def bond_mode
    @property_hash[:mode] || :absent
  end

  def bond_mode=(value)
    return unless self.type == :bonding

    begin
      File.write("/sys/class/net/#{@property_hash[:name]}/bonding/mode", value.to_s)
    rescue Exception => e
      notice e.message
    end

    @property_hash[:mode] = value
  end

  def bond_slaves
    @property_hash[:bond_slaves] || []
  end

  def bond_slaves=(value)
    return unless self.type == :bonding

    save_state_and_shutdown
    sync_bond_slaves(@property_hash[:name], self.bond_slaves, value)
    restore_state

    @property_hash[:bond_slaves] = value
  end

  def bond_xmit_hash_policy
    @property_hash[:xmit_hash_policy] || :absent
  end

  def bond_xmit_hash_policy=(value)
    return unless self.type == :bonding

    begin
      File.write("/sys/class/net/#{@property_hash[:name]}/bonding/xmit_hash_policy", value.to_s)
    rescue Exception => e
      e.message
    end

    @property_hash[:xmit_hash_policy] = value
  end


  ##
  ## Vlan
  ##

  def self.instance_vlan(name)
    hash = {}

    hash[:vlanid] = get_vlan_id(name)

    hash
  end

  def self.get_vlan_id(name)
    if name.include?('vlan')
      Integer(/\Avlan(\d+)\Z/.match(name)[1])
    else
      1
    end
  end

  def create_vlan
    self.parent = @resource[:parent]
    self.vlanid = @resource[:vlanid]
  end

  def destroy_vlan
    debug 'Destroy the interface %{name}.' % { name: @property_hash[:name] }
    ip(['link', 'delete', 'dev', @property_hash[:name], 'type', 'vlan'])
  end

  def parent
    @property_hash[:parent] || :absent
  end

  def parent=(value)
    @property_hash[:parent] = value
  end

  def vlanid
    @property_hash[:vlanid] || :absent
  end

  def vlanid=(value)
    return unless self.type == Puppet::Util::Network::Vlan

    ip(['link', 'add', 'name', @property_hash[:name], 'link', @property_hash[:parent], 'type', 'vlan', 'id', value.to_s])
    @property_hash[:vlanid] = value
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


  def interface_is_bonding?(name)
    File.directory?("/sys/class/net/#{name}/bonding")
  end


  def interface_exists?(name)
    File.symlink?("/sys/class/net/#{name}")
  end


  def get_interface_state(name)
    @state_hash[name] ||=
        begin
          File.read("/sys/class/net/#{name}/operstate").strip.to_sym
        rescue Exception =>  e
          notice e.message
          :down
        end

    @state_hash[name]
  end


  def sync_bond_slaves(bond, is, should)
    add_bond_slaves(bond, should - is)
    delete_bond_slaves(bond, is - should)
  end


  def manage_bond_slaves(bond, slaves, command = add)
    # Exit if no bond interface
    return unless interface_is_bonding?(bond)

    prefix = command == delete ? '-' : '+'

    slaves.each do |slave|
      next unless interface_exists?(slave)

      ip(['link', 'set', 'dev', slave, 'down']) if get_interface_state(slave) == :up
      begin
        File.write("/sys/class/net/#{bond}/bonding/slaves", "#{prefix}#{slave}")
      rescue Exception => e
        notice e.message
      end
      ip(['link', 'set', 'dev', slave, 'up']) if get_interface_state(slave) == :up
    end
  end

  def save_state_and_shutdown
    state = self.state
    if state == :up
      @state = state
      self.state = :down
    end
  end

  def restore_state
    self.state = @state
  end
end
