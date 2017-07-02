require 'spec_helper'

include Conjur::Policy

describe Resolver do
  fixtures_dir = File.expand_path("resolver-fixtures", File.dirname(__FILE__))

  Dir.chdir(fixtures_dir) do
    files = if env = ENV['POLICY_FIXTURES']
      env.split(',')
    else
      Dir['*.yml']
    end

    files.each do |file_example_name|
      example file_example_name do
        filename = File.expand_path file_example_name, fixtures_dir
        fixture = YAML.load File.read(filename), filename

        account = fixture['account'] || "the-account"
        ownerid = fixture['ownerid'] || "rspec:user:default-owner"
        namespace = fixture['namespace']

        allow(Conjur).to receive(:configuration).and_return double(:configuration, account: account)

        policy = Conjur::Policy::YAML::Loader.load fixture['policy']
        expect(Resolver.resolve(policy, account, ownerid, namespace).to_yaml).to eq(fixture['expectation'])
      end
    end
  end
end
