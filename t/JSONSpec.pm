#!perl

package JSONSpec;

use warnings;
use strict;

use Class::Accessor;
use File::Find;
use File::Spec;
use File::Basename qw(basename dirname);
use JSON;

use base qw(Class::Accessor);
JSONSpec->mk_accessors(qw(name context argv optspec expectation fixture));

our $SpecDir = File::Spec->join(dirname(__FILE__), '..', 'json_spec');

sub find_specs {
    my ($class, $dir) = @_;

    $dir ||= $SpecDir;

    my @files;
    my $spec_files = find(
        sub {
            /\.json$/ && push(@files, $File::Find::name);
        }, $dir);

    return @files;
}

sub get_specs {
    my ($class, $dir) = @_;

    return map { $class->new($_) } $class->find_specs;
}

sub fix {
    my ($self, $domain) = @_;

    my $filename = ($domain =~ m{/} ? $domain : File::Spec->join($ENV{'HOME'}, '.' . $domain));

    if ($self->fixture) {
        if (open(my $fh, '>', $filename)) {
            $fh->print(encode_json($self->fixture));
            close($fh);
        }
    } elsif (-f $filename) {
        unlink $filename;
    }
}

sub _readfile {
    my ($file) = @_;
    my $text;

    local $/;
    if (open(my $fh, '<', $file)) {
        $text = <$fh>;
        close($fh);
    } else {
        die "Couldn't open file $file - $!";
    }

    return $text;
}

sub new {
    my ($class, $file, $data) = @_;

    # Class::Accessor requires hash-based class
    my $self = bless({}, $class);

    $data ||= decode_json(_readfile($file));

    $self->name(basename($file));
    $self->context(basename(dirname($file)));
    $self->argv($data->[0]);
    $self->optspec($data->[1]);
    $self->expectation($data->[2]);
    $self->fixture($data->[3]);

    return $self;
}

1;
