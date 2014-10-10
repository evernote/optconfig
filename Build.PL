#!perl

use lib 'lib';
use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Optconfig',
     license  =>    'Apache_2_0',
     dist_author => 'Jeremy Brinkley <jbrinkley@evernote.com>',
     dist_version => sub {
         require 'OptconfigVersion.pm';
         $Optconfig::Version::VERSION;
     }->(),
     script_files => {
         'bin/perl-showconfig'      => 'bin/perl-showconfig'
     },
     pm_files => {
         'lib/Optconfig.pm'         => 'lib/Optconfig.pm',
         'lib/OptconfigVersion.pm'  => 'lib/OptconfigVersion.pm'
     },
     requires => {
         'perl'          => '5.6.1'
     },
    );

$build->create_build_script;
