#!ruby
# /* Copyright 2013 Proofpoint, Inc. All rights reserved.
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
# */

require 'longopt'
require 'rubygems'
require 'json'

class Optconfig < Hash

   attr_accessor :domain, :optspec, :config, :default

   def add_standard_opts(submitted_optspec)
      optspec = submitted_optspec
      standard_opts = {
         'config=s' => nil,
         'debug+' => 0,
         'verbose+' => 0,
         'version' => false,
         'help' => false,
         'dry-run!' => false }
      standard_opts.each_pair do |opt, defval|
         if ! optspec.has_key? opt
            optspec[opt] = defval
         end
      end
      optspec
   end

   def initialize(domain, submitted_optspec, cmdline=true)
      @domain = domain
      @optspec = add_standard_opts(submitted_optspec)
      submitted_optspec.each_pair do |optspec, val|
         opt, dummy = optspec.split(/[\=\+\!]/, 2)
         self[opt] = val
      end
      cfgfilepath = [ '/usr/local/etc/' + domain + '.conf' ]

      if ENV.has_key? 'HOME' and ! ENV['HOME'].nil?
         cfgfilepath.unshift(ENV['HOME'] + '/.' + domain)
      end
      @config = nil
      if cmdline
         cmdlineopt = Longopt.new(optspec.keys)
      else
         cmdlineopt = {}
      end
      if cmdlineopt.has_key? 'config'
         @config = cmdlineopt['config']
         raise "File not found: #{cmdlineopt['config']}" unless
            File.exist? cmdlineopt['config']
         read_config(cmdlineopt['config'])
      else
         cfgfilepath.each do |file|
            if File.readable? file
               @config = file
               read_config(file)
               break
            end
         end
      end

      cmdlineopt.each_pair do |opt, val|
         merge_cmdlineopt(opt, val)
      end

      if self.has_key? 'version' and self['version']
         if ! $VERSION.nil?
            puts $VERSION
         else
            puts "Unknown version"
         end
         Process.exit(0)
      end

      if self.has_key? 'help' and self['help']
         myscript = File.expand_path($0)
         had_usage = false
         begin
            in_usage = false
            File.open(myscript, 'r') do |fh|
               fh.each do |line|
                  if in_usage
                     had_usage = true
                     break if line.match(/^=/)
                     puts line
                  end
                  in_usage = true if line.match(/^=head1 +SYNOPSIS/)
               end
            end
         rescue Errno::ENOENT
         end
         unless had_usage
            puts "No help"
         end
         Process.exit(0)
      end
   end

   def read_config(file)
      fileconfig = File.open(file) { |fh| JSON.load(fh) }
      fileconfig.each_pair do |opt, val|
         self[opt] = val
      end
   end

   def merge_cmdlineopt(opt, val)
      if self.has_key? opt
         if self[opt].respond_to? :keys
            if val.respond_to? :keys
               # Both hashes, merge
               val.each_pair { |k, v| self[opt][k] = v }
            else
               self[opt] = val
            end
         elsif self[opt].respond_to? :unshift
            if val.respond_to? :each
               val.each { |v| self[opt].unshift(v) }
            else
               self[opt] = val
            end
         else
            self[opt] = val
         end
      else
         self[opt] = val
      end

      self[opt]
   end

   def vrb(level, *msg)
      puts msg.join("\n") if self['verbose'] >= level
   end

   def dbg(level, *msg)
      if self['debug'] >= level
         puts "DBG(#{@domain}): " + msg.join("DBG(#{@domain}):    ")
      end
   end

   @@manpage = <<'EOF'
=head1 NAME

Optconfig - Parse options and config files

=head1 SYNOPSIS

   opt = Optconfig.new(domain, { 'file=s' => '/var/log/file',
                                 'force!' => false,
                                 'define=s%' => { } })

   File.open(opt['file'], 'w') { |fh| fh.puts "Log entry" }

=head1 DESCRIPTION

This module implements a common config file and command-line option parsing
interface, including Optconfig standard options, that is shared with the
Optconfig Perl module. See that module for details.

=head1 AUTHOR

Jeremy Brinkley, E<lt>jbrinkley@proofpoint.comE<gt>

=cut

EOF

end
