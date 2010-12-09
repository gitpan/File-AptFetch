#!/usr/bin/perl
# $Id: 0.t 431 2010-12-05 01:07:42Z whynot $

use strict;
use warnings;

package main;
use version 0.50; our $VERSION = qv q|0.0.1|;

use t::TestSuite;
use Test::More;

my $apt_lib = t::TestSuite::FAF_discover_lib;
plan skip_all => q|not *nix, or misconfigured|        unless defined $apt_lib;
plan skip_all => q|not Debian, or alike|                      unless $apt_lib;

INIT { use_ok q|File::AptFetch|             or BAIL_OUT }
INIT { use_ok q|File::AptFetch::ConfigData| or BAIL_OUT }

use File::Temp   qw| tempdir tempfile |;
use Cwd;

File::AptFetch::ConfigData->set_config( timeout => 10 );

my $arena  = tempdir q|FAF_0_XXXXXX|;
my $lib_method = File::AptFetch::ConfigData->config( q|lib_method| );
my( $fh, $fake_method ) = tempfile q|FAF_0_XXXXXX|, DIR => $arena;
chmod 0755, $fh                                                or BAIL_OUT $!;
t::TestSuite::FAF_prepare_method *$fh, q|w-method|, $fake_method;
close $fh                                                      or BAIL_OUT $!;
$fake_method = ( split m{/}, $fake_method )[-1];

my $config_source = File::AptFetch::ConfigData->config( q|config_source| );
( $fh, my $fake_source ) = tempfile q|config_0_XXXXXX|, DIR => $arena;
chmod 0755, $fh                                                or BAIL_OUT $!;
t::TestSuite::FAF_prepare_method *$fh, q|y-method|, $fake_source,
  qq|Dir::Bin::methods "$arena";|;
close $fh                                                      or BAIL_OUT $!;
File::AptFetch::ConfigData->set_config( config_source => [ $fake_source ]);

my $rc  = File::AptFetch->init( $fake_method );
isa_ok $rc, q|File::AptFetch|                                 or BAIL_OUT $rc;

undef $rc;

my @fails;
while( -1 != ( my $pid = wait )) { push @fails, $pid }
t::TestSuite::FAF_diag join ' ', map qq|[$_]|, @fails               if @fails;
ok !@fails, scalar( @fails ) . q| zombies found|                  or BAIL_OUT;

t::TestSuite::FAF_clean_up $arena;
rmdir $arena;

ok !-d $arena, q|clean-ups|                                       or BAIL_OUT;

plan tests => 5;

# vim: syntax=perl
