require 'spec_helper'

describe Puppet::Type.type(:evs_ipnet) do
  let(:required_params) do
    {
      :name   => 'tenant/switch/net',
      :ensure => 'present'
    }
  end
  let(:optional_params) do
    {
      # properties
        :subnet => '192.168.10.0/24',
      #  :defrouter => '',
      #  :uuid => '',
      #  :pool => '',
      # parameters
    }
  end

  # Modify the params inline to tests when you modeling the
  # behavior of the generated resource
  let(:params) { required_params.merge(optional_params) }
  let(:resource) { described_class.new(params) }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }
  let(:error_pattern) { /failed on/ }

  it "has :name as its keyattribute" do
    expect( described_class.key_attributes).to eq([:name])
  end

  describe "has property" do
    [
      # list properties
        :ensure,
        :subnet,
        :defrouter,
        :uuid,
        :pool,
    ].each { |prop|
      it prop do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    }
  end
  describe "has parameter" do
    [
        :name,
    ].each { |param|
      it param do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    }
  end

# Input Validation
describe "parameter" do
  [:name].each do |type|
    context "#{type}" do
      context "accepts" do
        %w(foo/bar/baz).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.not_to raise_error
          end
        end
      end
      context "rejects" do
        %w(foo foo/bar/baz/quux foo:bar:baz).each do |thing|
          it thing.inspect do
            params[type] = thing
            expect { resource }.to raise_error(Puppet::Error, error_pattern)
          end
        end
      end
      it "fails if unset" do
        params.delete(type)
        expect { resource }.to raise_error(Puppet::Error, %r(must be provided))
      end
    end
  end
end # parameters

describe "property" do
    [:ensure].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(present absent).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(true false).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
        it "does not fail if unset" do
          params.delete(type)
          expect { resource }.not_to raise_error
        end
      end
    end
    [:subnet].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(1.2.3.0/24 fe80::3e07:54ff:fe53:c704/64).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(1.2.3.256 fe80::3e07::c704).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
        it "fails if unset" do
          params.delete(type)
          expect { resource }.to raise_error(Puppet::Error, %r(must be provided))
        end
      end
    end
    [:defrouter].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(10.10.10.1 fe80::3e07:54ff:fe53:c704).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(1.2.3.256 10.10.10.1/24 fe80::3e07:54ff:fe53:c704/24).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
        it "does not fail if unset" do
          params.delete(type)
          expect { resource }.not_to raise_error
        end
      end
    end
    [:uuid].each do |type|
      context "#{type}" do
        context "accepts" do
          %w(6c982de8-df63-4d1b-b3af-441cf2eb1959).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(8-df63-4d1b-b3af-441cf2eb19599 6c982de8-df63-4d1b-441cf2eb1959
          Lc982de8-df63-4d1b-b3af-441cf2eb1959).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
        it "does not fail if unset" do
          params.delete(type)
          expect { resource }.not_to raise_error
        end
      end
    end
    [:pool].each do |type|
      context "#{type}" do
        context "accepts" do
          # We are making assumptions about the ability to add
          # individual addresses to the pool
          %w(192.168.1.20-192.168.1.30
          192.168.1.20-192.168.1.30,192.168.1.50-192.168.1.80
          192.168.1.20 192.168.1.23,192.168.1.24).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.not_to raise_error
            end
          end
        end
        context "rejects" do
          %w(192.168.1.20-192.168.1.256
          192.168.1.20-192.168.1.30;192.168.1.50-192.168.1.80).each do |thing|
            it thing.inspect do
              params[type] = thing
              expect { resource }.to raise_error(Puppet::Error, error_pattern)
            end
          end
        end
        it "fails/does not fail if unset" do
          params.delete(type)
          expect { resource }.not_to raise_error
        end
      end
    end
end # properties


# describe "autorequire" do
#   # This assumes resource requires thing => two
#   it "does not require thing when no matching resource exists" do
#     thing = Puppet::Type.type(:thing).new(:name => "one")
#     catalog.add_resource thing
#     catalog.add_resource resource
#     expect(resource.autorequire.count).to eq 0
#   end
#   it "requires the matching thing resource" do
#     thing = Puppet::Type.type(:thing).new(:name => "two")
#     catalog.add_resource thing
#     catalog.add_resource resource
#     reqs = resource.autorequire
#     expect(reqs.count).to eq 1
#     expect(reqs[0].source).to eq thing
#     expect(reqs[0].target).to eq resource
#   end
# end
end
