require 'spec_helper'

describe Conjur::Policy::YAML::Loader do
  shared_examples_for "round-trip dsl" do |example|
    let(:filename) { "spec/round-trip/yaml/#{example}.yml" }
    it "#{example}.yml" do
      expect(Conjur::Policy::YAML::Loader.load_file(filename).to_yaml).to eq(File.read("spec/round-trip/yaml/#{example}.expected.yml"))
    end
  end

  shared_examples_for "error message" do |example|
    let(:filename) { "spec/errors/yaml/#{example}.yml" }
    it "#{example}.yml" do
      lines = File.read(filename).split("\n")
      location, message = lines[0..1].map{|l| l.match(/^#\s+(.*)/)[1]}
      line, column = location.split(',').map(&:strip)
      error_message = "Error at line #{line}, column #{column} in #{filename} : #{message}"
      expect { Conjur::Policy::YAML::Loader.load_file(filename).to_yaml }.to raise_error(Conjur::Policy::Invalid)
      begin
        Conjur::Policy::YAML::Loader.load_file(filename).to_yaml
      rescue Conjur::Policy::Invalid
        expect($!.message).to eq(error_message)
      end
    end
  end
  
  it_should_behave_like 'round-trip dsl', 'sequence'
  it_should_behave_like 'round-trip dsl', 'record'
  it_should_behave_like 'round-trip dsl', 'members'
  it_should_behave_like 'round-trip dsl', 'permit'
  it_should_behave_like 'round-trip dsl', 'permissions'
  it_should_behave_like 'round-trip dsl', 'deny'
  it_should_behave_like 'round-trip dsl', 'jenkins-policy'
  it_should_behave_like 'round-trip dsl', 'layer-members'
  it_should_behave_like 'round-trip dsl', 'all-types-all-fields'
  it_should_behave_like 'round-trip dsl', 'org'
  it_should_behave_like 'round-trip dsl', 'include'

  it_should_behave_like 'error message', 'unrecognized-type'
  it_should_behave_like 'error message', 'incorrect-type-for-field-1'
  it_should_behave_like 'error message', 'incorrect-type-for-field-2'
  it_should_behave_like 'error message', 'incorrect-type-for-array-field'
  it_should_behave_like 'error message', 'no-such-attribute'
end
