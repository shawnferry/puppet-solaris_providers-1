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

require 'puppet/property/list'
Puppet::Type.newtype(:evs_vport) do
  @doc = "Manage the configuration of EVS VPort"

  ensurable do
    newvalue(:present) do
      provider.create
    end

    newvalue(:absent) do
      provider.destroy
    end

    # Resets the specified VPort
    newvalue(:reset) do
      provider.reset
    end
  end

  newparam(:name) do
    desc "The full name of Virtual Port for EVS"
    validate do |value|
      if value.split("/").length != 3
        fail "Invalid VPort name\n" \
                             "Name convention must be <tenant>/<evs>/<vport>"
      end
    end
  end

  ## read/write properties (always updatable) ##
  newproperty(:cos) do
    desc "802.1p priority on outbound packets on the virtual port"
    newvalues(0,1,2,3,4,5,6,7)
  end

  newproperty(:maxbw) do
    desc "The full duplex bandwidth for the virtual port. Default unit is Mbps"
    newvalues(%r(^\d+[kmgKMG]$|^\d+$))
  end

  newproperty(:priority) do
    desc "Relative priority of virtual port"
    defaultto :medium
    newvalues(:high, :medium, :low)
  end

  newproperty(:protection, :array_matching => :all, :parent => Puppet::Property::List) do
    desc "Enables one or more types of link protection"
    defaultto [:"mac-nospoof", :"ip-nospoof"]
    newvalues(:"mac-nospoof", :restricted, :"ip-nospoof", :"dhcp-nospoof", :none)
    def should
      @should
    end
  end

  ## read-only properties (Settable upon creation) ##
  newproperty(:ipaddr) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "The IP address associated with the virtual port"
    validate do |val|
      unless valid_ip?(val)
        fail "#{val} is invalid"
      end
      if val.index('/')
        fail "#{value} cannot contain a subnet identifier"
      end
    end
  end

  newproperty(:macaddr) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "The MAC address associated with the virtual port"
    validate do |val|
      unless valid_macaddr?(val)
        fail "#{val} does not look like a MAC address"
      end
    end
  end

  newproperty(:uuid) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "UUID of the virtual port"
    validate do |val|
      unless valid_uuid?(val)
        fail "#{val} does not look like a UUID"
      end
    end
  end

  #XXX This should autorequire the switch

  validate do
    if self[:protection].include?(:none) && self[:protection].length > 1
      fail "cannot specify none with other protections"
    end
  end
end
