#!bash
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

# TODO:
# * --version doesn't really work, calling script continues after printing
# version.
# * --help doesn't work (because a) it prints the help on the stdout
# which is what gets eval'd, and b) it'll never find "-e"
# opt_new doesn't work, you have to eval it yourself, because otherwise
# the 'set' command which rearranges the script arguments doesn't work
# -jdb/20100921

opt_new_gen()
{
   local domain optspec
   domain="$1"
   shift 1
   optspec="$1"
   shift 1
   ruby \
      -e 'require "optconfig"' \
      -e 'require "json"' \
      -e 'require "bashon"' \
      -e '$VERSION = "'$SCRIPT_VERSION'"' \
      -e '$0 = "'"$0"'"' \
      -e 'd = ARGV.shift' \
      -e 'opttext = ARGV.shift' \
      -e 'optspec = JSON.load(opttext)' \
      -e 'opt = Optconfig.new(d, optspec)' \
      -e 'puts opt.map { |k,v| v.to_bashon("opt", d, k) }.join(";") + ";" +' \
      -e '   "opt_#{d}_vrb() { local l=\"$1\"; shift 1; test $l -le $(opt_#{d}_verbose) && echo $*; };" + ' \
      -e '   "opt_#{d}_dbg() { local l=\"$1\"; shift 1; test $l -le $(opt_#{d}_debug) && echo \"DBG(#{d}):\" $*; };" + ' \
      -e '   "opt_#{d}_dry() { if opt_#{d}_dry_run; then echo $*; else \"$@\"; fi; };" + ' \
      -e '   "opt_#{d}() { c=\"${1//[^a-zA-Z0-9]/_}\"; shift 1; opt_#{d}_$c \"$@\"; };" + ' \
      -e '   "set -- #{ARGV.map {|a| 39.chr + a + 39.chr}.join(%q( ))}"' \
      "$domain" "$optspec" "$@"
}

json2bashon_gen()
{
   ruby \
      -e 'require "bashon"' \
      -e 'require "json"' \
      -e 'name = ARGV.shift' \
      -e 'json_text = ARGV.shift' \
      -e 'obj = JSON.load(json_text)' \
      -e 'puts obj.to_bashon(name)' "$@"
}

json2bashon()
{
   eval `json2bashon_gen "$@"`
}
  

opt_new()
{
   # This doesn't work, but this is how it should work
   eval `opt_new_gen "$@"`
   echo opt_$1
}

:<<'EOF'
=head1 NAME

optconfig - Bash functions for option parsing

=head1 SYNOPSIS

   . optconfig.sh
   domain=domain
   optspec='{ "force!": false,
      "logfile=s": "/var/log/foo",
      "define=s%": { } }'
   # opt=`opt_new $domain $optspec`
   eval `opt_new_gen $domain "$optspec" "$@"`
   opt=opt_$domain

   if $opt force
   then
      rm -f $filefoo
   fi

   echo "Message" >>`$opt logfile`

   for key in `$opt define`
   do
      valfun=`$opt define $key`
      val=`$valfun`               # Note this call--all hash values are funs
      echo "$key = $val"
   done

=head1 DESCRIPTION

This bash "module" implements a common config file and command-line option
parsing interface, including Optconfig standard options, that is shared with
the Optconfig Perl module. See that module for details.

The initial call is a wrapper around the Ruby optconfig option and config
parsing library, and the results are serialized using the L<bashon> module.

=head1 NOTES

Pay careful attention to how L<bashon> serializes values, especially
collections. In particular the "leaf" value of a collection is always itself a
function. If the leaf is itself a collection, this will result in many command
invocations before you reach a simple value.

=head1 AUTHOR

Jeremy Brinkley, E<lt>jbrinkley@evernote.comE<gt>

=cut
EOF
