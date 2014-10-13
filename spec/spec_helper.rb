require 'optconfig'
require 'json'

class JSONSpec

    attr_accessor :name, :context, :argv, :optspec, :expectation

    @@spec_dir = File.join(File.dirname(__FILE__), '..', 'json_spec')

    def self.get_specs(dir=nil)
        dir ||= @@spec_dir
        dirs = Dir.glob("#{@@spec_dir}/**/*.json")
        dirs.map do |file|
            spec = JSONSpec.new(file)
        end
    end

    def fix(domain)
        filename = (domain.include?('/') ? domain : File.join(ENV['HOME'], '.' + domain))
        if @fixture
            File.open(filename, 'w') do |fh|
                fh.puts JSON.pretty_generate(@fixture)
            end
        end
    end

    def initialize(file, data=nil)
        data ||= File.open(file) { |fh| JSON.load(fh) }
        @name = File.basename(file)
        @context = File.basename(File.dirname(file))
        @argv = data[0]
        @optspec = data[1]
        @expectation = data[2]
        @fixture = data[3]
    end

end

