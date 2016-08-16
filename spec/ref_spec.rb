require 'spec_helper'
require 'conjur-policy-parser'

include Conjur::Policy::Types

describe "record reference" do
  describe "class LayerRef" do
    let(:ref) { LayerRef.new("the-layer") }
    let(:ref_yaml) {
      %Q(---
- !layer the-layer
)
    }
    let(:obj_yaml) {
      %Q(---
- !layer
  id: the-layer
)
    }
    it "is defined" do
      expect(LayerRef).to be
    end
    describe "emitting" do
      it "emits a YAML tag" do
        expect([ ref ].to_yaml).to eq(ref_yaml)
      end
    end
    describe "parsing" do
      it "parses as a Layer" do
        expect(Conjur::Policy::YAML::Loader.load(ref_yaml)[0]).to be_instance_of(Layer)
      end
      it "emits expected YAML" do
        expect(Conjur::Policy::YAML::Loader.load(ref_yaml).to_yaml).to eq(obj_yaml)
      end
    end
    describe "a comprehensive example" do
      let(:admin) { Group.new("admin") }
      let(:dev) { Group.new("dev") }
      it "emits expected YAML" do
        expect([
          admin,
          dev,
          Grant.new.tap do |grant|
            grant.role = GroupRef.new(dev.id)
            grant.member = GroupRef.new(admin.id)
          end
        ].to_yaml).to eq(<<-YAML)
---
- !group
  id: admin
- !group
  id: dev
- !grant
  member: !member
    role: !group admin
  role: !group dev
        YAML
      end
    end
  end
end
