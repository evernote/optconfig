require 'spec_helper'

describe Optconfig do
    before :all do
        @saved_argv = ARGV.dup
        @domain = 'test-example'
        ARGV.replace([])
    end

    after :all do
        # Probably not really needed
        ARGV.replace(@saved_argv)
    end

    context "with defaults" do

        subject { Optconfig.new(@domain, {}) }
        it { is_expected.to be_instance_of Optconfig }
        it { is_expected.to include 'verbose' => 0 }
        it { is_expected.to include 'debug' => 0 }
        it { is_expected.to include 'dry-run' => false }
        it { is_expected.to include 'version' => false }
        it { is_expected.to include 'help' => false }

        def using_optspec(kwargs)
            Optconfig.new(@domain, kwargs)
        end

        it "interprets simple option default" do
            expect(using_optspec('test' => true)['test']).to be_truthy
        end

        it "interprets boolean option default" do
            expect(using_optspec('test!' => false)['test']).to be_falsey
        end

    end

    context "with commandline" do

        def with_argv(argv, optspec)
            ARGV.replace(argv)
            Optconfig.new(@domain, optspec)
        end

        it "interprets simple option" do
            expect(with_argv(['--test'], 'test' => false)).to be_truthy
        end

        it "interprets boolean option" do
            expect(with_argv(['--test'], 'test!' => false)['test']).to be_truthy
        end

        it "interprets inverted boolean option" do
            expect(with_argv(['--notest'], 'test!' => true)['test']).to be_falsey
        end

        it "interprets count option" do
            expect(with_argv(['--test'], 'test+' => 0)['test']).to eq 1
        end

        it "interprets count option multiply" do
            expect(with_argv(['--test', '--test'], 'test+' => 0)['test']).to eq 2
        end

        it "interprets integer assignment" do
            expect(with_argv(['--test=9'], 'test=i' => 0)['test']).to eq 9
        end

        it "interprets integer optarg" do
            expect(with_argv(['--test', '9'], 'test=i' => 0)['test']).to eq 9
        end

        it "interprets string assignment" do
            expect(with_argv(['--test=nine'], 'test=s' => nil)['test']).to eq 'nine'
        end

        it "interprets string arrays" do
            expect(with_argv(['--test', 'nine'], 'test=s@' => nil)['test']).to match_array ['nine']
        end

        it "interprets string arrays multiply" do
            expect(with_argv(['--test', 'nine', '--test=ten'], 'test=s@' => nil)['test']).to match_array ['nine', 'ten']
        end

        it "interprets defines" do
            expect(with_argv(['--test=success=excellent'], 'test=s%' => nil)['test']).to include 'success' => 'excellent'
        end

        it "interprets defines multiply" do
            test = with_argv(['--test', 'success=excellent', '--test=failure=bad'], 'test=s%' => nil)['test']
            expect(test).to include 'success' => 'excellent'
            expect(test).to include 'failure' => 'bad'
        end

    end

end
