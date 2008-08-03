#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(../lib lib);
use WWW::CPANRatings::RSS;

my $rate = WWW::CPANRatings::RSS->new;

$rate->fetch
    or die $rate->error;

for ( @{ $rate->ratings } ) {
    printf "%s - %s stars - by %s\n--- %s ---\nsee %s\n\n\n",
        @$_{ qw/dist rating creator comment link/ };
}