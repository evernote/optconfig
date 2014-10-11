require 'spec_helper'
require 'fileutils'

$json_dir = File.join(File.dirname(__FILE__), '..', 'json_specs')

describe "Optconfig" do

    before(:all) do
        $saved_argv = ARGV.dup
    end

    after(:all) do
        ARGV.replace($saved_argv)
    end

    JSONSpec.get_specs.each do |json_spec|
        context (json_spec.context || 'general') do
            it json_spec.name do
                json_spec.fix 'test-example'

                ARGV.replace json_spec.argv

                expect(Optconfig.new('test-example',
                                     json_spec.optspec)).to include json_spec.expectation
            end
        end
    end

end
