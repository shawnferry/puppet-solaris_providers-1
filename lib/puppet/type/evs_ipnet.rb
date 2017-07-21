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

Puppet::Type.newtype(:evs_ipnet) do
  @doc = "Manage the configuration of IPnet (subnet of IPv4 or IPv6
            addresses).

          IPnet settings except pool cannot be changed after creation."

  ensurable
  newparam(:name) do
    desc "The full name of IPnet including tenant name. If no tenant is desired
    use the default value sys-global.

    i.e. oracle/switch1/net1, sys-global/switch1/net1"

    validate do |value|
      if value.split("/").length != 3
        fail "Name convention must be <tenant>/<evs>/<ipnet>"
      end
    end
  end

  ## read-only properties (updatable when idle) ##
  newproperty(:subnet) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "Subnet (either IPv4 or IPv6) for the IPnet.

    i.e. 192.168.10.0/24, fe80::3e07:54ff:fe53:c704/64
    "

    validate do |val|
      unless valid_ip?(val)
        fail "#{val} is not a valid network/mask"
      end
    end
  end

  newproperty(:defrouter) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "The IP address of the default router for the given IPnet.
    Defaults to the first address in the range."

    validate do |val|
      unless valid_ip?(val)
        fail "#{val} is invalid"
      end
      if val.index('/')
        fail "#{value} cannot contain a subnet identifier"
      end
    end
  end

  newproperty(:uuid) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "UUID of the IPnet"
    validate do |val|
      unless valid_uuid?(val)
        fail "#{val} does not look like a UUID"
      end
    end
  end

  ## read/write property (settable upon creation) ##
  newproperty(:pool) do
    include PuppetX::Oracle::SolarisProviders::Util::Validation
    desc "Sub-ranges of IP addresses within a subnet. Multiple ranges are
    seperated with commas.

    i.e.
    Single Range: 192.168.1.20-192.168.1.30
    Multiple Ranges: 192.168.1.20-192.168.1.30,192.168.1.50-192.168.1.80"

    # Newvalues is only filtering for acceptable characters
    newvalues(%r([,\-\d]+))

    validate do |val|
      val.split(',').each do |range|
       range.split('-').each do |ip|
         unless valid_ip?(ip)
           fail '#{ip} is not a valid IPaddress'
         end
       end
     end
    end
  end

  #XXX This should autorequire the switch

  validate do
    unless self[:subnet]
      fail "Subnet must be provided"
    end
  end
end
