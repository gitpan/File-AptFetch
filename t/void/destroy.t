# $Id: destroy.t 490 2014-01-26 18:44:36Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.50; our $VERSION = qv q|0.1.1|;

use t::TestSuite qw| :temp :mthd :file |;
use File::AptFetch;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan !defined $Apt_Lib                        ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => 3 );

my $arena = FAFTS_tempdir nick => q|arena|;
File::AptFetch::ConfigData->set_config(lib_method => $arena );
my $signal = File::AptFetch::ConfigData->config(q|signal|);
my $stderr = FAFTS_tempfile nick => q|stderr|, dir => $arena;

my( $method, $rv, $serr );
unless( !$ENV{FAFTS_NO_LIB} && $Apt_Lib)                              {
    t::TestSuite::FAFTS_diag q|missing APT: workarounds enabled|;
    my $cfg = FAFTS_tempfile nick => q|config|, dir => $arena;
    FAFTS_prepare_method
        $cfg, q|y-method|, $stderr, qq|Dir::Bin::methods "$arena";|;
    File::AptFetch::ConfigData->set_config( config_source => [ $cfg ]) }

$method = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtag4f84|, dir => $arena ), q|w-method|, $stderr;
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( $method ) };
ok !-s $stderr && !$serr, q|method is ready|;
undef $rv;
$serr = FAFTS_get_file $stderr;
chomp $serr;
is $serr, qq|{{{$signal}}}|, q|method is sent configured signal|;

$signal = File::AptFetch::ConfigData->config( q|signal| ) eq q|TERM| ?
  q|PIPE| : q|TERM|;
File::AptFetch::ConfigData->set_config(signal => $signal );
$method = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtaga643|, dir => $arena ), q|w-method|, $stderr;
( $rv, $serr ) = FAFTS_wrap { File::AptFetch->init( $method ) };
undef $rv;
$serr = FAFTS_get_file $stderr;
is $serr, qq|{{{$signal}}}\n|, q|method is sent reconfigured signal|;

# vim: syntax=perl
