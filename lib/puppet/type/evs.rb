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

require 'puppet/property/list'
Puppet::Type.newtype(:evs) do
  @doc = "Create and manage the configuration of Oracle Solaris Elastic Virtual Switch
           (EVS).

           Properties explicitly set for a VPORT override these values"

  ensurable
  newparam(:name) do
    desc "The full name for EVS (including the tenant name)"
    validate do |value|
      if value.split("/").length != 2
        fail "Invalid EVS name\n"\
                             "Name convention must be <tenant>/<evs>"
      end
    end
  end

  ## read/write properties (always updatable) ##
  newproperty(:maxbw) do
    desc "The full duplex bandwidth for the virtual port. Default Unit Mbps"
    newvalues(%r(^\d+[kmgKMG]$|^\d+$))
  end

  newproperty(:priority) do
    desc "The relative priority for the virtual port"
    defaultto :medium
    newvalues(:high, :medium, :low)
  end

  # tenant read only property

  newproperty(:protection, :array_matching => :all,
              :parent => Puppet::Property::List) do
    desc "Enables one or more types of link protection"
    defaultto [:"mac-nospoof", :"ip-nospoof"]
    newvalues(:"mac-nospoof", :restricted, :"ip-nospoof", :"dhcp-nospoof", :none)
    def should
      @should
    end
  end

  ## read-only properties (settable upon creation) ##
  newproperty(:l2_type) do
    desc "Layer 2 type"
    defaultto :vlan
    newvalues(:vlan, :vxlan, :flat)
  end

  newproperty(:vlanid) do
    desc "Default VLAN ID (tag) for this EVS. 1-4094"
    newvalues(%r(^\d+$))
    validate do |val|
      unless val.kind_of?(Integer)
        fail "#{val} must be an integer"
      end
      unless (1..4094).cover?(val)
        fail "${val} must be between 1-4094 inclusive"
      end
    end
  end

  newproperty(:vni) do
    desc "VXLAN Network Identifier (VNI) segment used to implement the EVS. 0-16777215"
    newvalues(%r(^\d+$))
    validate do |val|
      unless val.kind_of?(Integer)
        fail "#{val} must be an integer"
      end
      unless (0..16777215).cover?(val)
        fail "${val} must be between 0-16777215 inclusive"
      end
    end
  end

  newproperty(:uuid) do
    desc "UUID of the EVS instance"
    validate do |val|
      unless val =~ %r(\h{8}-(\h{4}-){3}\h{12})
        fail "#{val} does not look like a UUID"
      end
    end
  end

  validate do
    if self[:protection].include?(:none) && self[:protection].length > 1
      fail "cannot specify none with other protections"
    end
  end
end
