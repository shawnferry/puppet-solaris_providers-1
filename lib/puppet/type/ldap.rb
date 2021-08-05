#
# Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.
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

require_relative '../../puppet_x/oracle/solaris_providers/util/svcs.rb'
require 'puppet/property/list'

Puppet::Type.newtype(:ldap) do
  @doc = "Manage the configuration of the LDAP client for Oracle Solaris"
  include PuppetX::Oracle::SolarisProviders::Util::Validation

  ensurable

  newparam(:name) do
    desc "The symbolic name for the LDAP client settings to use. Name
              can only be the literal value 'current'"
    newvalues(:current)
    isnamevar
  end

  newproperty(:profile) do
    desc "The LDAP profile name"
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :astring
    desc "The LDAP profile name"
  end

  newproperty(:server_list, :parent => Puppet::Property::List) do
    desc "LDAP server names or addresses.  Specify multiple servers as an
              array"

    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :host

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a spaces/backslashes
    def delimiter
      /[\s\\]+/
    end

    # create a list using spaces as a delimiter
    def is_to_s(currentvalue)
      if currentvalue == :absent
        return "absent"
      else
        return currentvalue.join(" ")
      end
    end

    include PuppetX::Oracle::SolarisProviders::Util::Validation
    validate do |val|
      [val].flatten.each do |value|
        unless valid_ip?(value) || valid_hostname?(value)
          fail "value: #{value} is invalid"
        end
      end
    end
  end

  newproperty(:preferred_server_list, :parent => Puppet::Property::List) do
    desc "LDAP server(s) to contact before any servers listed in
              default_server_list"
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :host

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a spaces/backslashes
    def delimiter
      /[\s\\]+/
    end

    # create a list using spaces as a delimiter
    def is_to_s(currentvalue)
      if currentvalue == :absent
        return "absent"
      else
        return currentvalue.join(" ")
      end
    end

    include PuppetX::Oracle::SolarisProviders::Util::Validation
    validate do |val|
      [val].flatten.each do |value|
        unless valid_ip?(value) || valid_hostname?(value)
          fail "value: #{value} is invalid"
        end
      end
    end
  end

  newproperty(:search_base) do
    desc "The default search base DN"
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :astring
  end

  newproperty(:search_scope) do
    desc "The default search scope for the client's search operations."
    newvalues("base", "one", "sub")
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :astring
  end

  newproperty(:authentication_method, :parent => Puppet::Property::List) do
    desc "The default authentication method(s).  Specify multiple methods
              as an array."

    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :array

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.collect! {|x| x.to_s}
      self.should.collect! {|x| x.to_s}
      is.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end

    newvalues("none", "simple", "sasl/CRAM-MD5", "sasl/DIGEST-MD5",
              "sasl/GSSAPI", "tls:simple", "tls:sasl/CRAM-MD5",
              "tls:sasl/DIGEST-MD5")
  end

  newproperty(:credential_level) do
    desc "The credential level the client should use to contact the
              directory."
    newvalues("anonymous", "proxy", "self")
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :astring
  end

  newproperty(:search_time_limit) do
    desc "The maximum number of seconds allowed for an LDAP search
              operation."
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :integer

    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |val|
      is_integer?(val,true)
    end
  end

  newproperty(:bind_time_limit) do
    desc "The maximum number of seconds a client should spend performing a
              bind operation."
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :integer
    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |val|
      is_integer?(val,true)
    end
  end

  newproperty(:follow_referrals) do
    desc "The referral setting."
    newvalues(:true, :false)
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :astring
  end

  newproperty(:profile_ttl) do
    desc "The TTL value in seconds for the client information"
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    # astring is correct for the definition, checking as a count anyway 
    self.prop_type = :astring
    include PuppetX::Oracle::SolarisProviders::Util::Svcs
    validate do |val|
      is_count?(val,true)
    end
  end

  newproperty(:attribute_map, :parent => Puppet::Property::List) do
    desc "A mapping from an attribute defined by a service to an attribute
              in an alternative schema.  Specify multiple mappings as an array."

    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :array

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end
  end

  newproperty(:objectclass_map, :parent => Puppet::Property::List) do
    desc "A  mapping from an objectclass defined by a service to an
              objectclass in an alternative schema.  Specify multiple mappings
              as an array."

    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :array

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end
  end

  newproperty(:service_credential_level) do
    desc "The credential level to be used by a service."
    newvalues("anonymous", "proxy")
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :astring
  end

  newproperty(:service_authentication_method,
              :parent => Puppet::Property::List) do
    desc "The authentication method to be used by a service.  Specify
              multiple methods as an array."

    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :array

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end
  end

  newproperty(:service_search_descriptor, :parent => Puppet::Property::List) do
    desc "How and where LDAP should search for information for a particular
              service"
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "config"
    self.prop_type = :array

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end

  end


  newproperty(:bind_dn, :parent => Puppet::Property::List) do
    desc "An entry that has read permission for the requested database.
              Specify multiple entries as an array."

    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "cred"
    self.prop_type = :array

    # ensure should remains an array
    def should
      @should
    end

    def insync?(is)
      is = [] if is == :absent or is.nil?
      is.sort == self.should.sort
    end

    # svcprop returns multivalue entries delimited with a space
    def delimiter
      " "
    end
  end

  newproperty(:bind_passwd) do
    desc "password to be used for authenticating the bind DN."
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "cred"
    self.prop_type = :astring
  end

  newproperty(:enable_shadow_update) do
    desc "Specify whether the client is allowed to update shadow
              information."
    newvalues(:true, :false)
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "cred"
    self.prop_type = :astring
  end

  newproperty(:admin_bind_dn) do
    desc "The Bind Distinguished Name for the administrator identity that
              is used for shadow information update"
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "cred"
    self.prop_type = :opaque
  end

  newproperty(:admin_bind_passwd) do
    desc "The administrator password"
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "cred"
    self.prop_type = :opaque
  end

  newproperty(:host_certpath) do
    desc "The location of the certificate files"
    class << self
      attr_accessor :pg
      attr_accessor :prop_type
    end
    self.pg = "cred"
    self.prop_type = :astring
  end
end
