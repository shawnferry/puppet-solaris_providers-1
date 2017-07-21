#
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require_relative '../../puppet_x/oracle/solaris_providers/util/validation.rb'
Puppet::Type.newtype(:evs_properties) do
  @doc = "Manage global properties of EVS(Elastic Virtual Switch) for both
            client and controller. There are two instances associated with
            contoller and client properties respectively. See: evsadm (1M)"

  ensurable

  ## This is a property setter, thus not ensurable ##
  newparam(:name) do
    desc "Type of properties
         Name must be 'controller_property' or 'client_property'"
    newvalues(*%w(controller_property client_property))
  end

  ## Properties associated with "controller_property" ##
  ## All the properties are read/write
  newproperty(:l2_type) do
    desc "Define how an EVS will be implemented across machines
         (controller_property)"
    defaultto :vlan
    newvalues(*%i[vlan vxlan flat])
  end


  newproperty(:uplink_port) do
    desc "Specifies the datalink to be used for VLANs or VXLANs
    (controller_property)

    Simple Format: 'uplink_port' => 'net0'

    Preferred Complex Format: Hash of Values
    ```
    {
      'uplink-port'   => 'net0',
      'vlan-range'    => '10-20[,30-40]',
      'vxlan-range'   => '10-20[,30-40]',
      'host'          => 'foo'
      'flat'          => 'yes|no'
    }
    ```

    Deprecated Complex Format:

    Semi-colon seperated set of positional uplink-port properties.
    uplink_port => '<port>;<vlan-range>[,...];<vxlan-range>[,...];<host>;<flat>'
    "

    newvalues(
      %r(^\w+\d$),
      %r(^\w+\d;((\d+-\d+)?(,(\d+-\d+))?;){2}([\w.]+)?;(?:yes|no)?$)
    )

    # Form the argument string
    # [-h host] uplink-port=<port>[,...]
    munge do |val|
      super(val)
      arg_arry = []
      value = if val.kind_of?(String)
                deprecation_warning "string format arguments are deprecated. Move to Hash style arguments."
                to_h(val)
              else
                val
              end

      unless value['host'].to_s.empty?
        arg_arry.push('-h', value.delete('host').to_s)
      end

      arg_arry.push('-p', '')

      # If uplink-port doesn't have to be first the next two steps
      # could be dropped
      arg_arry[-1] << "uplink-port=#{value.delete('uplink-port')}"
      arg_arry[-1] << ',' unless value.empty? # No arguments
      arg_arry[-1] << value.to_a.map do |k,v|
        # Assign key to value use an empty string for :absent
        # to unset / reset to system default
        "#{k}=#{v == :absent ? '' : v}"
      end.join(',')
      return arg_arry
    end

    def to_h(str)
      val={}
      str.split(';').each_with_index do |thing,idx|
        next if thing.nil? || thing.empty?
        case idx
        when 0
          val['uplink-port'] = thing
        when 1
          val['vlan-range'] = thing
        when 2
          val['vxlan-range'] = thing
        when 3
          val['host'] = thing
        when 4
          val['flat'] = thing
        end
      end
      val
    end

    validate do |v|
      # Convert to hash and check values later
      val = if v.kind_of?(String)
              super(v)
              to_h(v)
            elsif v.kind_of?(Hash)
              v
            else
              fail "#{v.inspect}:#{v.class} must be an String or Hash"
            end

      val.each_pair do |key,value|
        # Allow :absent
        next if value == :absent

        case key
        when 'uplink-port'
          next if value =~ %r(^\w+\d$)
          fail "#{key}: #{val} does not look like a network interface"
        when 'vlan-range'
          _valid_range = (1..4094)
          value.split(',').each do |range|
            unless range =~ %r(^\d+\-\d+$)
              fail "#{key}: #{range} does not look like a range dddd-dddd"
            end
            _start, _end = range.split('-').map(&:to_i)
            unless _valid_range.cover?(_start)
              fail "#{_start} in #{range} is not a valid VLAN ID"
            end
            unless _valid_range.cover?(_end)
              fail "#{_end} in #{range} is not a valid VLAN ID"
            end
            unless _start.to_i < _end.to_i
              fail "#{range} start greater than end"
            end
          end
        when 'vxlan-range'
          _valid_range = (0..16777215)
          value.split(',').each do |range|
            unless range =~ %r(^\d+\-\d+$)
              fail "#{key}: #{range} does not look like a range dddd-dddd"
            end
            _start, _end = range.split('-').map(&:to_i)
            unless _valid_range.cover?(_start)
              fail "#{_start} in #{range} is not a valid VXLAN ID"
            end
            unless _valid_range.cover?(_end)
              fail "#{_end} in #{range} is not a valid VXLAN ID"
            end
            unless _start.to_i < _end.to_i
              fail "#{range} start greater than end"
            end
          end
        when 'flat'
          next if value =~ %r(^(yes|no)$)
          fail "#{key}: #{value} can only be yes/no"
        when 'host'
          # Only checking for word characters this may still be an invalid
          # host name
          next if value =~ %r(^[\w.]+$)
          fail "#{key}: #{value} does not look like a host name"
        end
      end
    end
  end

  newproperty(:uri_template, :array_matching => :all) do
    desc "URI template to build per-EVS Node RAD Connection
    (controller_property)

    Provide multiple entries an array

         The syntax of the uri_template value will be of the form:
         Set the default for all hosts:
          ```
         unix://
         ssh://
          ```

         Provider specific format to set template for a specific host:
          ```
         unix://[host]
         ssh://[host]
          ```

         Arguments are mapped into -h [host] -p uri_template=[template]

        It is not possible to unset a uri_template for a host via puppet.
    "

    defaultto 'ssh://'

    newvalues(%r(^(unix|ssh)://;?([\w.]+)?$),:absent)

    munge do |value|
      super(value)
      arg_arry = []
      if value.to_sym == :absent
        arg_arry.push('-p', 'uri_template=')
      else
        conn, for_host = value.split(%r(://;?),-1)
        unless for_host.empty?
          arg_arry.push('-h', for_host)
        end
        arg_arry.push('-p', 'uri-template=%<conn>s://' % {conn: conn})
      end
      arg_arry
    end

    validate do |value|
      super(value)
      if value.index(';')
        deprecation_warning "Remove ; from this argument"
      end
    end
  end

  newproperty(:vlan_range) do
    desc "List of VLAN ID ranges that will be used for creating EVS "\
      "(controller_property)\n"\
      "The maximum valid range is 1-4094"
    newvalues(%r(^\d+$),%r(^(\d+-\d+)?(,(\d+-\d+))?+$))
    validate do |value|
      super(value)
      _valid_range = (1..4094)
      value.split(',').each do |range|
        unless range =~ %r(^\d+\-\d+$)
          fail "#{key}: #{range} does not look like a range dddd-dddd"
        end
        _start, _end = range.split('-').map(&:to_i)
        unless _valid_range.cover?(_start)
          fail "#{_start} in #{range} is not a valid VLAN ID"
        end
        unless _valid_range.cover?(_end)
          fail "#{_end} in #{range} is not a valid VLAN ID"
        end
        unless _start.to_i < _end.to_i
          fail "#{range} start greater than end"
        end
      end
    end
  end

  newproperty(:vxlan_addr) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "IP address on top of which VXLAN datalink should be created
         (controller_property)

         Provide multiple/additional per-host vxlan addresses as a list.

         Simple Format: `vxlan_addr => [IP|subnet]`

         Perferred Complex Format:
         ```
         {
           'vxlan-addr'  => [IP|subnet],
           'vxlan-range' => [range]
           'host'        => [host]
         }
         ```
        Deprecated complex format.
         vxlan_addr => '<vxlan_IP_addr>;[<vxlan-range>];[<host>]'
    "

    # Convert to hash format argument
    def to_h(str)
      val={}
      # convert to hash
      str.strip().split(";").each_with_index do |v,idx|
        case idx
        when 0
          val['vxlan-addr'] = v
        when 1
          val['vxlan-range'] = v
        when 2
          val['host'] = v
        end
      end
      val
    end

    validate do |val|
      value = if val.kind_of?(Hash)
                val
              else
                to_h(val)
              end

      value.each_pair do |k,v|
        case k
        when 'vxlan-addr'
          unless valid_ip?(v)
            fail "#{v} is not a valid IP or subnet"
          end
        when 'vxlan-range'
          _valid_range = (0..16777215)
          v.split(',').each do |range|
            unless range =~ %r(^\d+\-\d+$)
              fail "#{key}: #{range} does not look like a range dddd-dddd"
            end
            _start, _end = range.split('-').map(&:to_i)
            unless _valid_range.cover?(_start)
              fail "#{_start} in #{range} is not a valid VXLAN ID"
            end
            unless _valid_range.cover?(_end)
              fail "#{_end} in #{range} is not a valid VXLAN ID"
            end
            unless _start.to_i < _end.to_i
              fail "#{range} start greater than end"
            end
          end
        when 'host'
          unless %r(^[\w\.]+$) =~ v
            fail "#{v} does not look like a host name"
          end
        end
      end
    end

    # Create argument array
    munge do |val|
      value = unless val.kind_of?(Hash)
                to_h(val)
              else
                val
              end

      arg_arry = []
      unless value['host'].to_s.empty?
        arg_arry.push('-h', value.delete('host').to_s)
      end

      arg_arry.push('-p', '')

      # If vxlan-addr doesn't have to be first the next two steps
      # could be dropped
      arg_arry[-1] << "vxlan-addr=#{value.delete('vxlan-addr')}"
      arg_arry[-1] << ',' unless value.empty? # No arguments
      arg_arry[-1] << value.to_a.map do |k,v|
        # Assign key to value use an empty string for :absent
        # to unset / reset to system default
        "#{k}=#{v == :absent ? '' : v}"
      end.join(',')
    end
  end

  newproperty(:vxlan_ipvers) do
    desc "IP version of the address for VXLAN datalinks "\
      "(controller_property)"
    defaultto :v4
    newvalues(*%i(v4 v6))
  end

  newproperty(:vxlan_mgroup) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "Multicast address that needs to be used while creating VXLAN
      links (controller_property).

      If mgroup is not provided it defaults to the 'all-host' address.

      Multicast addresses are in the folllowing subnets:
      ```
      224.0.0.0/4
      FF00::/8
      ```
    "

    validate do |value|
      unless valid_multicast?(value)
        fail "#{value} is not a multicast address"
      end
    end
  end

  newproperty(:vxlan_range) do
    desc "List of VXLAN ID ranges that will be used for creating EVS "\
      "(controller_property)\n"\
      "The maximum valid range is 0-16777215"
    newvalues(%r(^(\d+-\d+)?(,(\d+-\d+))?+$))

    validate do |v|
      super(v)
      _valid_range = (0..16777215)
      v.split(',').each do |range|
        unless range =~ %r(^\d+\-\d+$)
          fail "#{range} does not look like a range dddd-dddd"
        end
        _start, _end = range.split('-').map(&:to_i)
        unless _valid_range.cover?(_start)
          fail "#{_start} in #{range} is not a valid VXLAN ID"
        end
        unless _valid_range.cover?(_end)
          fail "#{_end} in #{range} is not a valid VXLAN ID"
        end
        unless _start.to_i < _end.to_i
          fail "#{range} start greater than end"
        end
      end
    end
  end


  ### The read/write property associated with "client_property" ###
  newproperty(:controller) do
    desc "SSH address of EVS controller server (client_property)"
    newvalues(
      %r(ssh://[\w\.]+^),
      %r(^ssh://(([\w\.]+)@)?[\w\.]+$),
      %r(unix://)
    )
  end
end
