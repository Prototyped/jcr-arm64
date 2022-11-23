#!/usr/bin/env perl

use strict;
use warnings;

use constant LIST_FILENAME => '/var/lib/apt/lists/releases.jfrog.io_artifactory_artifactory-debs_dists_buster_main_binary-amd64_Packages';
use constant NEW_LIST_FILENAME => '/var/lib/apt/lists/releases.jfrog.io_artifactory_artifactory-debs_dists_buster_main_binary-amd64_Packages.fixed';

my $section;
my $pkg_name;

open LIST_FILE, 'lz4 -d ' . (&LIST_FILENAME) . '.lz4|'
    or die 'Failed to open ', (&LIST_FILENAME), ': ', $!;

open NEW_LIST_FILE, '>', (&NEW_LIST_FILENAME)
    or die 'Failed to open ', (&NEW_LIST_FILENAME), ': ', $!;

while (my $line = <LIST_FILE>) {
    chomp $line;
    if ($line eq '') {
        if ($pkg_name) {
            print NEW_LIST_FILE $section;
            $pkg_name = '';
        }
        $section = '';
    } elsif ($line =~ /^Package: (.+)$/) {
        $pkg_name = $1;
    }
    $section .= $line . "\n";
}

if ($section && $pkg_name) {
    print NEW_LIST_FILE $section;
}

close NEW_LIST_FILE;

close LIST_FILE;

rename((&NEW_LIST_FILENAME), (&LIST_FILENAME));
unlink((&LIST_FILENAME) . '.lz4');
