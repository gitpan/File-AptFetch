# $Id: set_callback.t 497 2014-03-17 23:44:36Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :temp :mthd :file :diag |;
use File::AptFetch;
use Test::More;

my( $arena, $stderr, $fsrc, $ftrg, $mthd );
my( $faf, $rv, $serr );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan                        !defined $Apt_Lib ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => 8 );

( $rv, $serr ) = FAFTS_wrap                           {
    File::AptFetch::set_callback q|tag+8af5| => sub { }};
like $rv, qr{unknown callback}, q|unknown callback|;

( $rv, $serr ) = FAFTS_wrap                         {
    File::AptFetch::set_callback read => q|tag+b68a| };
like $rv, qr{isn't CODE}, q|not CODE|;

$arena = FAFTS_tempdir nick => q|dtag0551|;
$fsrc = FAFTS_tempfile nick => q|ftag1c44|, dir => $arena;
$ftrg = FAFTS_tempfile nick => q|ftag33c8|, dir => $arena;
$stderr = FAFTS_tempfile nick => q|stderr|;
$mthd = FAFTS_prepare_method
  FAFTS_tempfile( nick => q|mtagf0bc|, dir => $arena ),
  q|w-method|, $stderr;
File::AptFetch::ConfigData->set_config( lib_method => $arena );
( $rv, $serr ) = FAFTS_wrap                                    {
    File::AptFetch::set_callback read => sub { die q|tag+b679| }};
ok !$serr, q|{STDERR} is empty|;

File::AptFetch::ConfigData->set_config( timeout => 3 );
File::AptFetch::ConfigData->set_config( tick    => 1 );
( $faf, $serr ) = FAFTS_wrap { File::AptFetch->init( $mthd ) };
isa_ok $faf, q|File::AptFetch|, q|[init]|;
ok !$serr, q|{STDERR} is empty|;

( $rv, $serr ) = FAFTS_wrap { $faf->request( $ftrg, $fsrc ) };
is_deeply { rv => $rv, stderr => $serr }, { rv => '',     stderr => '' },
  q|[request]|;
( $rv, $serr ) = FAFTS_wrap { $faf->gain };
like $rv, qr{tag.b679}, q|sets [read] callback|;
undef $faf;
is FAFTS_get_file $stderr, qq|{{{TERM}}}\n|, q|{STDERR} is empty|;

# vim: syntax=perl
