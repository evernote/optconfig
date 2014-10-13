#!perl

#
# Copyright 2013 Proofpoint, Inc. All rights reserved.
# Copyright 2014 Evernote Corp. All rights reserved.
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
#

=head1 NAME

Optconfig - Parse command-line options and configuration files

=head1 DESCRIPTION

This Perl module implements the Optconfig standard for command-line
option parsing merged with JSON-based configuration file interpretation.
See the reference documentation in the Optconfig master distribution.

=cut

package Optconfig;

use strict;
use OptconfigVersion;
use Getopt::Long;
use JSON;
use Data::Dumper;
use Carp;
use File::Spec;
use FindBin;

use vars qw($VERSION $standard_opts);

# It's okay that this is distinct from the other libraries. Mostly -jdb/20141008
$VERSION = $Optconfig::Version::VERSION;

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
   my ($class, $domain, $submitted_optspec, $version) = @_;

   my $self = bless({ }, $class);
   $self->{'_domain'} = $domain;
   $self->{'_optspec'} = _add_standard_opts($submitted_optspec);
   $self->{'_version'} = $version || $main::VERSION || 'Unknown version';

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
       print $self->{'_version'}, "\n";
      exit(0);
   }

   if ($self->{'help'}) {
       my $text;
       my $error_text;
       my $myscript = File::Spec->catfile($FindBin::RealBin, $FindBin::RealScript);

       {
           local $/;
           if (open(my $fh, '<', $myscript)) {
               $text = <$fh>;
               close($fh);
           } else {
               $error_text = "No help (could not search $myscript)";
           }
       }
       my ($help_text) = $text =~ /(?:^=head1 +SYNOPSIS)(.*?)(?:^=head1)/msg;
       if ($help_text) {
           $help_text =~ s/^[\w\n]*//ms;
           $help_text =~ s/[\w\n]*$//ms;
           print $help_text, "\n";
       } else {
           print(($error_text || 'No help'), "\n");
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
