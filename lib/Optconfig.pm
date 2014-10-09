#!perl
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

=head1 NAME

Optconfig - Configure and parse command-line options

=head1 SYNOPSIS

   # Invoking an optconfig program

   program [options] arguments...
      --config=file    Use file for configuration
      --verbose        Produce verbose output
      --dry-run        Do a dry run (don't change things)
      --version        Print program version number
      --help           Print usage message
      --debug          Produce debugging output
      Some programs will have options specific to them

   # In optconfig program
   use Optconfig;

   # Configuration is read from
   my $opt = Optconfig->new('domain', { 'force!' => 0,
                                        'logfile=s' => '/var/log/foo',
                                        'define=s%' });

   unlink($filefoo) if $opt->{'force'};

   open(my $fh, '>', $opt->{'logfile'}) and print $fh, "Message\n";

   for my $key (keys %{$opt->{'define'}}) {
      print "$key = $opt->{'define'}->{$key}\n";
   }

=head1 DESCRIPTION

The Optconfig module looks in various places for its configuration. It will
read configuration from I<one> of C<$HOME/.domain>,
C</usr/local/etc/domain.conf>, C</etc/domain.conf> and the configuration file (if any) specified
with the B<--config> command-line option.

The whole configuration is read from the file (even if the option spec doesn't
contain those configuration items), and values can be overridden by
command-line options specified in the option spec.

There is a standard set of options you can pass (or configure in a config
file) to Optconfig programs.

=head2 Standard Options

=over

=item --config=file

Optconfig reads the configuration in the named file. The configuration file
format is JSON.  If it can't read this file, it complains. If no --config
option is specified, it will search for a configuration file in the standard
locations as listed above. If it finds a file, it reads it and sets config
values accordingly, then overrides or merges these values with the ones on
the command line.

Some options can be specified multiple times. For example, a --define option
might allow you to define more than one key; or a --host option might allow
you to define more than one host. If these options appear in the configuration
file and the command line, their values are added to by the command line value
For example, if you have a configuration file with the following contents:

   { "define": { "name": "bob", "home": "/home/bob" }
     "host": [ "wiki.ppops.net", "tickets.ppops.net" ] }

And you pass C<--define mail=bob@opsexample.com> C<--host=mail.opsexample.net> into
the command, the resulting configuration will be:

   { "define": { "mail": "bob@opsexample.com", "name": "bob",
                 "home": "/home/bob" },
     "host": [ "mail.opsexample.net", "wiki.opsexample.net", "tickets.opsexample.net" ] }

Note how the command-line value for C<--host> is prepended to the list.

=item --verbose

Produce verbose output. You can specify this a number of times indicating
increased verbosity.

=item --dry-run

The command will print what it would have done, but won't change anything in
databases or on disk.

=item --version

Print the program version.

=item --help

Print a help message.

=item --debug

Producing debugging output. You can specify this a number of times indicating
increased debugging output volume.

=back

=head2 Using the Optconfig Module

=head3 Option Signatures

=over 4

=item config=s

The config file is a string. You don't have to do anything with it.

=item verbose+

The 'verbose' option value is a number indicating the verbosity level. You can
test this and/or use the L<vrb()> method.

=item debug+

The 'debug' option value is a number indicating the level. You can test this
and/or use the L<vrb()> method.

=item dry-run!

This is a boolean indicating whether a dry run is happening. You need to test
this when performing operations that would change persistent data. For example:

   my $sth = $dbh->prepare("DROP TABLE $tab");
   $opt->vrb(1, "Dropping table users");
   $sth->execute() unless $opt->{'dry-run'};
   $sth->finish();

=item version

Define a global variable $VERSION and Optconfig will print it out.

=item help

If your program has a pod page with a SYNOPSIS section, Optconfig will print
it out.

=back

=head3 Class Methods

=over 4

=item new($domain, \%options)

Parse command-line options and configuration files using $domain.

Each pair in the option hash is composed of an option specifer and a default
value. The option specifier is exactly that given in the L<Getopt::Long>
module.

=back

=head3 Object Methods

=over 4

=item vrb($level, $msg, ...)

Prints verbose output if the --verbose level is at or greater than the
verbosity mentioned. Thus, if you specify a level of 1, the message will be
printed if the user has specified C<--verbose>. If you specify a level of 3,
the user will have to pass C<--verbose --verbose --verbose> to see it.

=item dbg($level, $msg, ...)

Similar to L<vrb()>, but uses the value of the C<--debug> option and prints
a tag indicating the domain.

=back

=head1 BUGS

When consulting a configuration file, Optconfig should check the options for
adherence to the optspec, and it doesn't. This could result in unclear
failures in the program where the wrong type is configured (for example,
a scalar for a list).

There's no easy way to "empty out" an already-configured list or map value
from the configuration. In the example above, there's no combination of
command-line options that would result in a one-element list for the 'host'
option.

When Optconfig is merging the command-line options into the configuration,
it is affected by the type of the existing option value (from the configuration
file) whereas it should honor only the optspec.

=head1 AUTHOR

Jeremy Brinkley, E<lt>jbrinkley@evernote.comE<gt>

=head1 SEE ALSO

=over 4

=item showconfig

=back

=cut

package Optconfig;

use strict;
use Getopt::Long;
use JSON;
use Data::Dumper;
use Carp;
use File::Spec;
use FindBin;

use vars qw($VERSION $standard_opts);

# It's okay that this is distinct from the other libraries. Mostly -jdb/20141008
$VERSION = '1.1';

BEGIN {
   $standard_opts = {
      'config=s' => undef,
      'debug+' => 0,
      'verbose+' => 0,
      'version' => 0,
      'help' => 0,
      'dry-run!' => 0 };
}

sub _add_standard_opts {
   my ($optspec) = @_;

   for my $opt (keys %$standard_opts) {
      if (! exists($optspec->{$opt})) {
         $optspec->{$opt} = $standard_opts->{$opt};
      }
   }

   return $optspec;
}

sub new {
   my ($class, $domain, $submitted_optspec) = @_;

   my $self = bless({ }, $class);
   $self->{'_domain'} = $domain;
   $self->{'_optspec'} = _add_standard_opts($submitted_optspec);

   my $cmdlineopt = { };
   my $defval = { };
   my @optspecs = ( );

   for my $optspec (keys %$submitted_optspec) {
      my $val = $submitted_optspec->{$optspec};
      push(@optspecs, $optspec);
      my ($opt, $dummy) = split(/[=\!\+]/, $optspec, 2);
      $self->{$opt} = $val;
   }

   GetOptions($cmdlineopt,
              @optspecs);

   my $cfgfilepath = [ '/usr/local/etc/' . $domain . '.conf',
                       '/etc/' . $domain . '.conf' ];
   unshift(@$cfgfilepath, $ENV{'HOME'} . '/.' . $domain)
       if defined($ENV{'HOME'});
   $self->{'_config'} = undef;

   if (exists($cmdlineopt->{'config'})) {
      croak "File not found: $cmdlineopt->{'config'}"
         unless -r $cmdlineopt->{'config'};
      eval {
         $self->read_config($cmdlineopt->{'config'});
      };
      if ($@) {
         croak $@;
      }
   }
   else
   {
      for my $file (@$cfgfilepath) {
         eval {
            if (-r $file) {
               $self->{'_config'} = $file;
               $self->read_config($file);
               last;
            }
         };
         if ($@) {
            carp "Error reading config file $file: $@";
         }
      }      
   }

   for my $opt (keys %$cmdlineopt) {
      $self->merge_cmdlineopt($opt, $cmdlineopt->{$opt});
   }

   $self->ocdbg(Data::Dumper->Dump([$self], ['optconfig']));

   if ($self->{'version'}) {
      if (defined($main::VERSION)) {
         print $main::VERSION, "\n";
      } else {
         print "Unknown version\n";
      }
      exit(0);
   }

   if ($self->{'help'}) {
      # Find ourselves
      if (open(my $fh, '<', File::Spec->catfile($FindBin::RealBin, $FindBin::RealScript))) {
         my $in_usage = 0;
         my $had_usage = 0;
         while (defined(my $line = <$fh>)) {
            if ($in_usage) {
               $had_usage = 1;
               last if $line =~ /^=/;
               print $line;
            }
            $in_usage = 1 if $line =~ /^=head1 +SYNOPSIS/;
         }
         close($fh);
         if (! $had_usage) {
            print "No help\n";
         }
      } else {
         print STDERR "Can't find executable location\n";
         exit(10);
      }
      exit(0);
   }

   return $self;
}

sub _val {
   my ($val) = @_;

   Data::Dumper->new([$val], ['val'])->Terse(1)->Dump;
}

# This logic is based on the value of the existing (configured) option value
# but it should be based on the type of the optspec. -jdb/20100812
sub merge_cmdlineopt {
   my ($self, $opt, $val) = @_;

   $self->ocdbg("->merge_cmdlineopt('$opt', " . _val($val));

   if (exists($self->{$opt})) {
      if (ref($self->{$opt})) {
         if (ref($self->{$opt}) eq 'HASH') {
            if (ref($val) and ref($val) eq 'HASH') {
               # Merge, at least one-level
               for my $k (keys %$val) {
                  $self->{$opt}->{$k} = $val->{$k};
               }
            } else {
               # The value given is a simple scalar value, all I can
               # do is blow away the hash. Also, same consideration as
               # below with the configured array value and the passed-in
               # non-array value. -jdb/20100812
               $self->{$opt} = $val;
            }
         } elsif (ref($self->{$opt}) eq 'ARRAY') {
            if (ref($val) and ref($val) eq 'ARRAY') {
               # The command-line values get put in *front* of the configured
               # values.
               unshift(@{$self->{$opt}}, @$val);
            } else {
               # This happens when the type of the optspec is NOT ...@, but
               # the configuration file has a list value for this option.
               # It shouldn't really happen. In this circumstance the right
               # thing to do is follow the optspec instead of the configuration
               # because the optspec is under the control of the programmer (so
               # the program will actually expect the option value to match it)
               # while the configuration comes from heck-know-where (and we
               # should probably complain if it doesn't match the optspec
               # anyway). -jdb/20100812
               $self->{$opt} = $val;
            }
         } else {
            # It's a reference, but not a hash or array reference. Whuh?
            # Blast it away.
            $self->{$opt} = $val;
         }
      } else {
         # Scalar value: override
         $self->{$opt} = $val;
      }
   } else {
      # Not configured: normal set value
      $self->{$opt} = $val;
   }

   return $self->{$opt};
}

# TODO: read_config should be cognizant of the option types, in particular
# things like =s@.
sub read_config {
   my ($self, $file) = @_;
   my $obj;

   if (open(my $fh, '<', $file)) {
      my $text = do { local $/; <$fh> };
      close($fh);

      $obj = _from_json($text);
      for my $opt (keys %$obj) {
         $self->{$opt} = $obj->{$opt};
      }
   } else {
      croak $!;
   }

   return $obj;
}

sub _from_json {
   my ($text) = @_;

   if ($JSON::VERSION >= 2.0) {
      return from_json($text);
   } else {
      return jsonToObj($text);
   }
}

sub _to_json {
   my ($obj) = @_;

   if ($JSON::VERSION >= 2.0) {
      return to_json($obj);
   } else {
      return objToJson($obj);
   }
}

sub hash {
   my ($self) = @_;

   my $hash = { };

   for my $key (keys %$self) {
      $hash->{$key} = $self->{$key} unless $key =~ /^_/;
   }

   return $hash;
}

sub vrb {
   my ($self, $level, @msg) = @_;

   print join("\n", @msg), "\n"
      if ($level <= $self->{'verbose'});
}

sub dbg {
   my ($self, $level, @msg) = @_;

   print "DBG($self->{'_domain'}): ",
      join("\nDBG($self->{'_domain'}): ", @msg), "\n"
         if ($level <= $self->{'debug'});
}

sub ocdbg {
   # This debugging is controlled by an environment variable, because
   # it's really orthogonal to the use of a 'debug' option in the constructor
   # or something like that. -jdb/20100812
   print "DBG(Optconfig): ", join("\nDBG(Optconfig):    ", @_), "\n"
      if $ENV{'OPTCONFIG_DEBUG'};
}

1;
