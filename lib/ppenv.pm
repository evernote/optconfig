#!perl
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


# @INC now is like this:
# /usr/local, PERLLIB-dirs, system-lib-dirs
# I need to get rid of /usr/local
# I need to save the dirs that came from PERLLIB
# Put /usr/local/lib ahead of all the system libpath dirs
# and put back PERLLIB dirs. Otherwise, you'll never be able
# to override modules in /usr/local/lib
# use lib '/usr/local/lib';
use Config;
BEGIN {
   no warnings;

   if ($INC[0] eq '/usr/local') {
      shift(@INC);
   }
   my @perllib = ();
   my @saved_perllib = ();
   if ($ENV{'PERL5LIB'}) {
      @perllib = split(':', $ENV{'PERL5LIB'});
   } elsif ($ENV{'PERLLIB'}) {
      @perllib = split(':', $ENV{'PERLLIB'});
   }

   if (@perllib) {
      while ($perllib[0] eq $INC[0]) {
         push(@saved_perllib, shift(@perllib));
         shift(@INC);
      }
   }

   my %libpath;
   for my $libpathkey (qw(archlib archlibexp
                       installarchlib installprivlib installsitearch
                       installsitelib
                       privlib privlibexp sitearch sitearchexp
                       sitelib sitelibexp sitelib_stem)) {
      my $libpath = $Config{$libpathkey};
      if (-d $libpath) {
         $libpath{$libpath} = 1;
      }
   }

   for my $libpath (keys %libpath) {
      $libpath =~ s{^(.*?)(lib64|lib)}{/usr/local/$2};
      unshift(@INC, $libpath);
   }
   unshift(@INC, '/usr/local/lib');
   unshift(@INC, @saved_perllib);
}

1;
