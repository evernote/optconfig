#!perl

use Test::More;
use Test::Deep;
use File::Spec;
use File::Basename;
use Carp;

use lib File::Basename::dirname(__FILE__);
use JSONSpec;

use Optconfig;

plan tests => (scalar(JSONSpec->find_specs()));

sub strip_json_bs {
    my ($v) = @_;

    if (ref($v)) {
        if (ref($v) eq 'HASH') {
            # Can't use anonymous hash constructor here. Because Perl.
            my %anon = (map { $_ => strip_json_bs($v->{$_}) } keys %$v);
            \%anon;
        } elsif (ref($v) eq 'ARRAY') {
            [ map { strip_json_bs($_) } @$v ];
        } elsif (ref($v) =~ /JSON/) {
            if (JSON::is_bool($v)) {
                if ($v) {
                    1;
                } else {
                    0;
                }
            } elsif ($v == JSON::null) {
                undef;
            } else {
                croak "Don't know how to handle $v";
            }
        } else {
            croak "Don't know how ta handle $v";
        }
    } else {
        $v;
    }
}

our $json_dir = File::Spec->join(File::Basename::dirname(__FILE__), '..', 'json_specs');
our @saved_argv = (@ARGV);


for my $json_spec (JSONSpec->get_specs()) {
    
    my $context = ($json_spec->context || 'general');

    $json_spec->fix('test-example');
    @ARGV = (@{$json_spec->argv});

    my $opt = Optconfig->new('test-example',
                             $json_spec->optspec);

    cmp_deeply(strip_json_bs($opt->hash), superhashof(strip_json_bs($json_spec->expectation)),
               $json_spec->context . ' ' . $json_spec->name);
}

