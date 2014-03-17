# $Id: default.t 497 2014-03-17 23:44:36Z whynot $
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

my( @units, $dsrc, $dtrg, $file, $faux );
my( $faf, $rv, $serr, $fdat );

@units =
([{ tag => q|tag+9d89| },
  sub    { $fdat = { } },
  [ undef,    '',   { }]                                                ],
 [{ tag => q|tag+e15c|,                 eval => [qw| filename |]},
  sub                                                          {
      $file = FAFTS_tempfile nick => q|ftag7351|, dir => $dsrc;
      unlink $file;
      $fdat = { filename => $file }                             },
  [ 1,                                                         '',
    { filename => q|$file|, tmp => undef, flag => 4, tick => 5 }]       ],
 [{ tag => q|tag+3bb8|,                 eval => [qw| filename |]},
  sub                                       { $fdat->{flag} = 1 },
  [ 1,                                                         '',
    { filename => q|$file|, tmp => undef, flag => 0, tick => 5 }]       ],
 [{ tag => q|tag+9929|,                   eval => [qw| filename |]},
  sub                                                           { },
  [ '',                                                        '',
    { filename => q|$file|, tmp => undef, flag => -1, tick => 5 } ]     ],
 [{ tag => q|tag+0eeb|,                 eval => [qw| filename tmp |]},
  sub                                                              {
      $file = FAFTS_tempfile nick => q|ftag5dd0|, dir => $dsrc;
      $fdat = { filename => $file }                                 },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 0, back => 0,
      flag => 4,              factor => 1,              tick => 5 } ]   ],
 [{ tag => q|tag+1eea|,                  eval => [qw| filename tmp|]},
  sub                                                             { },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 0, back => 0,
      flag => 3,              factor => 1,              tick => 5 } ]   ],
 [{ tag => q|tag+25c7|,                 eval => [qw| filename tmp |]},
  sub                     { FAFTS_append_file $file, qq|tag+6e20\n| },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 9, back => 0,
      flag => 4,              factor => 1,              tick => 5 } ]   ],
 [{ tag => q|tag+7932|,                 eval => [qw| filename tmp |]},
  sub                                                             { },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 9, back => 9,
      flag => 3,              factor => 1,              tick => 5 } ]   ],
 [{ tag => q|tag+9d70|,                  eval => [qw| filename tmp |]},
  sub                      { FAFTS_append_file $file, qq|tag+4f90\n| },
  [ 1,                                                            '',
    { filename => q|$file|, tmp => q|$file|, size => 18, back => 9,
      flag => 4,              factor => 1,               tick => 5 } ]  ],
 [{ tag => q|tag+a29e|,                  eval => [qw| filename tmp |]},
  sub                         { FAFTS_set_file $file, qq|tag+86ad\n| },
  [ 1,                                                            '',
    { filename => q|$file|, tmp => q|$file|, size => 9, back => 18,
      flag => 4,               factor => 1,              tick => 5 } ]  ],
 [{ tag => q|tag+4fbc|,                 eval => [qw| filename tmp |]},
  sub                                    { FAFTS_set_file $file, '' },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 0, back => 9,
      flag => 4,              factor => 1,              tick => 5 } ]   ],
 [{ tag => q|tag+0f84|,                  eval => [qw| filename |]},
  sub                                             { unlink $file },
  [ 1,                                                        '',
    { filename => q|$file|, tmp => undef, size => 0, back => 9,
      flag => 3,             factor => 1,            tick => 5 } ]      ],
 [{ tag => q|tag+3038|,             init => !0 },
  sub                                         {
      $file = FAFTS_tempfile
        nick => q|ftag0bc6|, dir => $dsrc, content => qq|tag+9b87\n|;
      $fdat = { filename => $file, tick => 5 } }                        ],
 [{ tag => q|tag+7cba|,                  eval => [qw| filename |]},
  sub                                             { unlink $file },
  [ 1,                                                        '',
    { filename => q|$file|, tmp => undef, size => 9, back => 0,
      flag => 3,            factor => 1,             tick => 5 } ]      ],
 [{ tag => q|tag+3551|,                 eval => [qw| filename tmp |]},
  sub                        { FAFTS_set_file $file, qq|tag+e6c3\n| },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$file|, size => 9, back => 9,
      flag => 2,              factor => 1,              tick => 5 } ]   ],
 [{ tag => q|tag+c909|,                 eval => [qw| filename tmp |]},
  sub                                                              {
      $file = FAFTS_tempfile nick => q|ftag56c6|, dir => $dsrc;
      unlink $file;
      $faux = ( File::Temp::tempfile
        sprintf( q|%s.XXXX|, ( split m{/}, $file)[-1]), DIR => $dsrc )[-1];
      FAFTS_diag qq|\$faux: $faux|;
      FAFTS_set_file $faux, qq|tag+e94a\n|;
      $fdat = { filename => $file }                                 },
  [ 1,                                                           '',
    { filename => q|$file|, tmp => q|$faux|, size => 9, back => 0,
      flag => 4,              factor => 1,              tick => 5 } ]   ],
 [{ tag => q|tag+9f0f|,                  eval => [qw| filename tmp |]},
  sub                      { FAFTS_append_file $faux, qq|tag+9930\n| },
  [ 1,                                                            '',
    { filename => q|$file|, tmp => q|$faux|, size => 18, back => 9,
      flag => 4,              factor => 1,               tick => 5 } ]  ],
 [{ tag => q|tag+90be|,                  eval => [qw| filename |]},
  sub                                                           {
      unlink $faux;
      FAFTS_set_file $file, qq|tag+8e1e\ntag+e7e4\ntag+b4ee\n|   },
  [ 1,                                                          '',
    { filename => q|$file|, tmp => undef, size => 18, back => 9,
      flag => 3,             factor => 1,             tick => 5 }]      ],
 [{ tag => q|tag+e7c0|,                   eval => [qw| filename tmp |]},
  sub                                                               { },
  [ 1,                                                             '',
    { filename => q|$file|, tmp => q|$file|, size => 27, back => 18,
      flag => 4,               factor => 1,               tick => 5 } ] ] );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan                        !defined $Apt_Lib ?
( skip_all => q|not *nix, or misconfigured| ) : ( tests => scalar @units );

$dsrc = FAFTS_tempdir nick => q|dtag0551|;

while( my $unit = shift @units )                                     {
    $unit->[1]->();
    $unit->[2][2]{$_} = eval $unit->[2][2]{$_} foreach @{$unit->[0]{eval}};
    ( $rv, $serr ) = FAFTS_wrap { File::AptFetch::_read_callback( $fdat ) };
    FAFTS_show_message %$fdat;
    if( $unit->[0]{init} )                                          {
        ok !$serr, $unit->[0]{tag}                                   }
    else                                                            {
        $serr = $serr =~ m($unit->[0]{stderr})          if $unit->[0]{stderr};
        is_deeply [ $rv, $serr, $fdat ], $unit->[2], $unit->[0]{tag} }}

# vim: syntax=perl
