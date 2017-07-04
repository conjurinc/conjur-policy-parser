require 'spec_helper'
require 'conjur/policy/yaml/loader'

describe Conjur::Policy::YAML::Loader do
  describe "parses valid policy files correctly" do
    Dir["#{__dir__}/round-trip/yaml/*.expected.yml"].each do |exp|
      src = exp.sub '.expected', ''
      example src[/.*\/(.*)\.yml/, 1] do
        expect(Conjur::Policy::YAML::Loader.load_file(src).to_yaml).to \
            eq File.read exp
      end
    end
  end

  describe "raises informative errors with invalid input" do
    Dir["#{__dir__}/errors/yaml/*.yml"].each do |src|
      example src[/.*\/(.*)\.yml/, 1] do
        location, message = File.readlines(src).grep(/^#/).take 2
        line, column = location.scan(/\d+/)
        message.sub!(/^#\s*/, '').strip!

        expect { Conjur::Policy::YAML::Loader.load_file(src) }.to \
            raise_error(Conjur::Policy::Invalid) do |err|
          expect(err.message).to eq \
              "Error at line #{line}, column #{column} in #{src} : #{message}"
        end
      end
    end
  end
end
