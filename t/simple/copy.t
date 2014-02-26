# $Id: copy.t 496 2014-02-26 17:39:18Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package main;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use t::TestSuite qw| :mthd :temp :file |;
use File::AptFetch::Simple;
use Test::More;

File::AptFetch::ConfigData->set_config( timeout => 10 );

my $Apt_Lib = t::TestSuite::FAFTS_discover_lib;
plan
  !defined $Apt_Lib ? ( skip_all => q|not *nix, or misconfigured| ) :
  !$Apt_Lib           ?     ( skip_all => q|not Debian, or alike| ) :
  !-x qq|$Apt_Lib/copy| ? ( skip_all => q|missing method [copy:]| ) :
                                                    ( tests => 22 );

use t::TestSuite qw| :temp :mthd :diag |;
use Test::More;

use File::AptFetch;
File::AptFetch::ConfigData->set_config( timeout => 10 );

my( $dira, $dirb, $dirc, $fsra, $fsrb, $ftga, $ftgb );
my( $fafs, $rv, $serr, $tmpl );

my @purg;
END { unlink @purg if @purg }

$dira = FAFTS_tempdir nick => q|dtag7b1a|;
$dirb = FAFTS_tempdir nick => q|dtagbb1b|;

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request( q|copy| ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|sCM|;
ok !$serr, q|tag+4456 {STDERR} is empty|;
$tmpl =
{ rv => qq|$fafs|, stderr => '', status => 201, log => [ ], mark => 0 };

$fsra = FAFTS_tempfile
  nick => q|ftag9017|, dir => $dira, content => q|tag+d3c9|;
push @purg, $ftga = ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                                         q|tag+6421 one file|;

$fsra = FAFTS_tempfile
  nick => q|ftagb1f5|, dir => $dira, content => q|tag+7dac|;
push @purg, $ftga = ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request( $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                                    q|tag+6e08 no {%options}|;

$fsra = FAFTS_tempfile
  nick => q|ftag1e3b|, dir => $dira, content => q|tag+a24c|;
$fsrb = FAFTS_tempfile
  nick => q|ftag7121|, dir => $dira, content => q|tag+499e|;
push @purg,
  $ftga = ( split m{/}, $fsra )[-1], $ftgb = ( split m{/}, $fsrb )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra, $fsrb ) };
is_deeply
{ rv => qq|$rv|,  stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                 mark => $fafs->{mark},
  fila => FAFTS_get_file $ftga, filb => FAFTS_get_file $ftgb         },
{ %$tmpl, fila => FAFTS_get_file $fsra, filb => FAFTS_get_file $fsrb },
                                                 q|tag+b672 two files|;

$fsra = FAFTS_tempfile
  nick => q|dtag0431|, dir => $dira, content => q|tag+fa7e|;
$fsrb = FAFTS_tempfile
  nick => q|dtag1f06|, dir => $dira, content => q|tag+9aad|;
push @purg,
  $ftga = ( split m{/}, $fsra )[-1], $ftgb = ( split m{/}, $fsrb )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request( $fsra, $fsrb ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr,  status => $fafs->{Status},
  log => $fafs->{log},                 mark => $fafs->{mark},
  fila => FAFTS_get_file $ftga, filb => FAFTS_get_file $ftgb         },
{ %$tmpl, fila => FAFTS_get_file $fsra, filb => FAFTS_get_file $fsrb },
                                             q|tag+1b24 no {%options}|;

$fsra = FAFTS_tempfile
  nick => q|ftagce97|, dir => $dira, content => q|tag+f262|;
$fsrb = FAFTS_tempfile
  nick => q|ftag55fa|, dir => $dirb, content => q|tag+3162|;
push @purg,
  $ftga = ( split m{/}, $fsra )[-1], $ftgb = ( split m{/}, $fsrb )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra, $fsrb ) };
is_deeply
{ rv => qq|$rv|,  stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                 mark => $fafs->{mark},
  fila => FAFTS_get_file $ftga, filb => FAFTS_get_file $ftgb         },
{ %$tmpl, fila => FAFTS_get_file $fsra, filb => FAFTS_get_file $fsrb },
                                     q|tag+d1e5 two files in two dirs|;

$fsra = FAFTS_tempfile
  nick => q|ftag9fa1|, dir => $dira, content => q|tag+0596|;
$ftga = sprintf q|%s/%s|, $dirb, ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => $dirb }, $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                   q|tag+be17 overriding default {$location}|;

$dirc = FAFTS_tempdir nick => q|dtag81e3|;
( $fafs, $serr ) = FAFTS_wrap                                              {
  File::AptFetch::Simple->request({ method => q|copy|, location => $dirc }) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|cCM {$location}|;
ok !$serr, q|tag+6f56 {STDERR} is empty|;
$tmpl->{rv} = qq|$fafs|;

$fsra = FAFTS_tempfile
  nick => q|ftag36db|, dir => $dira, content => q|tag+8fcb|;
$ftga = sprintf q|%s/%s|, $dirc, ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                                         q|tag+38c4 one file|;

$fsra = FAFTS_tempfile
  nick => q|ftagf512|, dir => $dira, content => q|tag+6b3f|;
$ftga = sprintf q|%s/%s|, $dirc, ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request( $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                                    q|tag+e6f7 no {%options}|;

$fsra = FAFTS_tempfile
  nick => q|ftagaba8|, dir => $dira, content => q|tag+f101|;
$fsrb = FAFTS_tempfile
  nick => q|ftagb65d|, dir => $dira, content => q|tag+3b8e|;
$ftga = sprintf q|%s/%s|, $dirc, ( split m{/}, $fsra )[-1];
$ftgb = sprintf q|%s/%s|, $dirc, ( split m{/}, $fsrb )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra, $fsrb ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr,  status => $fafs->{Status},
  log => $fafs->{log},                 mark => $fafs->{mark},
  fila => FAFTS_get_file $ftga, filb => FAFTS_get_file $ftgb         },
{ %$tmpl, fila => FAFTS_get_file $fsra, filb => FAFTS_get_file $fsrb },
                                                 q|tag+4b89 two files|;

$fsra = FAFTS_tempfile
  nick => q|ftag007c|, dir => $dira, content => q|tag+f3b3|;
$fsrb = FAFTS_tempfile
  nick => q|ftagebda|, dir => $dirb, content => q|tag+e1c3|;
$ftga = sprintf q|%s/%s|, $dirc, ( split m{/}, $fsra )[-1];
$ftgb = sprintf q|%s/%s|, $dirc, ( split m{/}, $fsrb )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ }, $fsra, $fsrb ) };
is_deeply
{ rv => qq|$rv|,  stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                 mark => $fafs->{mark},
  fila => FAFTS_get_file $ftga, filb => FAFTS_get_file $ftgb         },
{ %$tmpl, fila => FAFTS_get_file $fsra, filb => FAFTS_get_file $fsrb },
                                     q|tag+08e5 two files in two dirs|;

$fsra = FAFTS_tempfile
  nick => q|ftagc528|, dir => $dira, content => q|tag+7787|;
$ftga = sprintf q|%s/%s|, $dirb, ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => $dirb }, $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                   q|tag+3c2d overriding default {$location}|;

$fsra = FAFTS_tempfile
  nick => q|ftagd231|, dir => $dira, content => q|tag+e09e|;
push @purg, $ftga = ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => q|.| }, $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                   q|tag+0cbc overriding default {$location}|;

$fsra = FAFTS_tempfile
  nick => q|ftagf838|, dir => $dirc, content => q|tag+5c90|;
$ftga = sprintf q|%s/%s|, $dira, ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => $dira }, $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                   q|tag+9446 overriding default {$location}|;

$dirc = substr $dirb, 1;
$dirc =~ s{[^/]+/}{}                                           until -d $dirc;
$fsra = FAFTS_tempfile
  nick => q|ftaga3c9|, dir => $dira, content => q|tag+f1e8|;
$ftga = sprintf q|%s/%s|, $dirb, ( split m{/}, $fsra )[-1];
delete $tmpl->{rv};
( $rv, $serr ) = FAFTS_wrap                            {
    File::AptFetch::Simple->request(
      { method => q|copy|, location => $dirc }, $fsra ) };
is_deeply
{ stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log}, mark => $fafs->{mark},
                file => FAFTS_get_file $ftga },
{ %$tmpl,       file => FAFTS_get_file $fsra },
             q|cCM {$location} isn't absolute|;
$tmpl->{rv} = qq|$fafs|;

$dirc = substr $dirb = FAFTS_tempdir( nick => q|dtag89f5| ), 1;
$dirc =~ s{[^/]+/}{}                                           until -d $dirc;
$fsra = FAFTS_tempfile
  nick => q|ftagc85d|, dir => $dira, content => q|tag+915a|;
$ftga = sprintf q|%s/%s|, $dirb, ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request({ location => $dirc }, $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                            q|cUM {$location} isn't absolute|;

( $fafs, $serr ) = FAFTS_wrap { File::AptFetch::Simple->request( q|file| ) };
isa_ok $fafs, q|File::AptFetch::Simple|, q|sCM {$method} (file)|;
ok !$serr, q|tag+6751 {STDERR} is empty|;
$tmpl->{rv} = qq|$fafs|;

$fsra = FAFTS_tempfile
  nick => q|ftag821d|, dir => $dira, content => q|tag+9ee5|;
push @purg, $ftga = ( split m{/}, $fsra )[-1];
( $rv, $serr ) = FAFTS_wrap { $fafs->request( $fsra ) };
is_deeply
{ rv => qq|$rv|, stderr => $serr, status => $fafs->{Status},
  log => $fafs->{log},                mark => $fafs->{mark},
                               file => FAFTS_get_file $ftga },
{ %$tmpl,                      file => FAFTS_get_file $fsra },
                                          q|[file] is [copy]|;

# vim: syntax=perl
