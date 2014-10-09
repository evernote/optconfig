#!ruby
# /* Copyright 2013 Proofpoint, Inc. All rights reserved.
#    Copyright 2014 Evernote Corp. All rights reserved.
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

require 'getoptlong'

class Longopt < Hash

   attr_accessor :optspec

   def Longopt.new_with_args(argv, *optspecs)
      obj = Longopt.allocate
      obj.getopts_with_argv(argv, *optspecs)
      obj
   end

   def getopts_with_args(argv, *optspeclist)
      saveargv = ARGV.dup
      # produces warning
      ARGV.replace(argv)
      getopts(*optspeclist)
      ARGV.replace(saveargv)
      self
   end

   def Longopt.default(opth)
      obj = Longopt.allocate
      obj.merge(opth)
   end

   def initialize(*optspecs)
      getopts(*optspecs)
   end

   def getopts(*optspecs)
      @optspec = { }

      if optspecs.size == 1 and optspecs[0].respond_to? :to_ary
         optspecs = optspecs[0]
      end

      optspecs.each do |optspec|
         if m = /^([\w_\-]+)([=:!+].*)/.match(optspec)
            opt = m[1]
            @optspec[opt] = { }

            act, typ, collect_typ = m[2].split('')

            case act

            when '='
               @optspec[opt]['gol-argument-type'] =
                  GetoptLong::REQUIRED_ARGUMENT
               @optspec[opt]['type-letter'] = typ
               @optspec[opt]['collection-type'] = collect_typ

            when ':'
               @optspec[opt]['gol-argument-type'] =
                  GetoptLong::OPTIONAL_ARGUMENT
               @optspec[opt]['type-letter'] = typ
               @optspec[opt]['collection-type'] = collect_typ

            when '!'
               @optspec[opt]['gol-argument-type'] = GetoptLong::NO_ARGUMENT
               @optspec[opt]['type-letter'] = 'b'
               @optspec['no' + opt] = { }
               @optspec['no' + opt]['gol-argument-type'] =
                  GetoptLong::NO_ARGUMENT

            when '+'
               @optspec[opt]['gol-argument-type'] = GetoptLong::NO_ARGUMENT
               @optspec[opt]['type-letter'] = 'a'

            end
         else
            @optspec[optspec] = { }
            @optspec[optspec]['gol-argument-type'] = GetoptLong::NO_ARGUMENT
            @optspec[optspec]['type-letter'] = 'b'
         end
      end

      gol_arguments = @optspec.map { |opt, optspec|
         ['--' + opt,
          optspec['gol-argument-type']]
      }

      GetoptLong.new(*gol_arguments).each do |k, v|
         k = k.sub(/^--/, '')

         case k

         when *booleans
            self[k] = true

         when *nobooleans
            self[k[2..-1]] = false

         when *simples
            self[k] = simple_value(k, v)

         when *lists
            self[k] = [ ] unless key? k
            self[k].push(simple_value(k, v))

         when *mappings
            self[k] = { } unless key? k
            mkey, mvalue = v.split(/=/, 2)
            self[k][mkey] = simple_value(k, mvalue)

         end
      end

   end

   def simple_value(opt, optarg)
      case @optspec[opt]['type-letter']
      when 's'
         optarg
      when 'i'
         Integer(optarg)
      when 'f'
         Float(optarg)
      when 'a'
         if key? opt
            rv = self[opt] + 1
         else
            rv = 1
         end
         rv
      else
         nil
      end
   end

   def booleans
      @optspec.reject { |k, v| v['type-letter'] != 'b' }.keys
   end

   def nobooleans
      @optspec.reject { |k, v| v['type-letter'] != 'b' }.keys.map { |el| 'no' + el }
   end

   def simples
      @optspec.reject { |k, v| ! v['collection-type'].nil? ||
                              v['type-letter'].nil? ||
                              v['type-letter'] == 'b' }.keys
   end

   def lists
      @optspec.reject { |k, v| v['collection-type'] != '@' }.keys
   end

   def mappings
      @optspec.reject { |k, v| v['collection-type'] != '%' }.keys
   end

   @@manpage = <<'EOF'
=head1 NAME

Longopt - Convenience class similar to Perl Getopt::Long

=head1 SYNOPSIS

   require 'longoopt'

   opt = Longopt.new('verbose', 'force!', 'logfile=s',
                     'define=s%', 'user=s@')

   print "Verbose enabled" if opt['verbose']

   unlink(filefoo) if opt['force']

   File.open(opt['logfile'], 'w') { |fh| fh << "Log message" }

   opt['user'].each { |user| notify_user(user) }

   opt['define'].each { |key, value| puts "#{key} = #{value}" }

=head1 DESCRIPTION

The Longopt class wraps GetoptLong so that you can use option specifiers
similar to the Perl Getopt::Long module.

Longopt is a Hash subclass.

=head2 Class Methods

=over 4

=item new(*optspecs)

Parse ARGV for options and set options according to provided optspecs.

=item new_with_args(args, *optspecs)

Like new(), but use provided arguments rather than ARGV.

=item default(opthash)

Create a Longopt object using the provided default option values in the
opthash. Use getopts(), below, to parse arguments.

=back

=head2 Object Methods

=item getopts(*optspecs)

Parse ARGV to set option values according to provided optspecs.

=item getopts_with_args(args, *optspecs)

Parse args to set option values according to provided optspecs.

=back

=head1 AUTHOR

Jeremy Brinkley, E<lt>jbrinkley@evernote.comE<gt>

=cut

EOF

end

