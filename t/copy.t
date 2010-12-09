#!/usr/bin/perl
# $Id: copy.t 431 2010-12-05 01:07:42Z whynot $

use strict;
use warnings;

package main;
use version 0.50; our $VERSION = qv q|0.0.7|;

use t::TestSuite qw|
  FAF_wrap_stderr FAF_unwrap_stderr FAF_fetch_stderr
  FAF_safe_wrapper FAF_wait_and_gain
  FAF_show_message FAF_clean_up       |;
use File::AptFetch;
use File::AptFetch::ConfigData;
use Test::More;
use File::Temp   qw| tempdir tempfile |;
use Cwd;

File::AptFetch::ConfigData->set_config( timeout => 10 );

my @fn;
our %units;

my $Copy_Has_Md5hash = 1;

$fn[0] = t::TestSuite::FAF_discover_lib;
plan
  !defined $fn[0]                               ?
    (skip_all => q|not *nix, or misconfigured|) :
  !$fn[0]                                       ?
    (skip_all => q|not Debian, or alike|)       :
  !-x qq|$fn[0]/copy|                           ?
    (skip_all => q|missing method (copy)|)      :
    (tests    => 89);
undef @fn;

$units{void} = sub {
    $fn[0] = File::AptFetch->init(q|copy|);
    isa_ok $fn[0], q|File::AptFetch|,
      q|C<copy> method initializes|;
    is $fn[0]{Status}, 100,
      q|C<copy> method is ready|;
    ok !@{$fn[0]{log}},
      q|I<@log> is processed|;
    ok !!@{$fn[0]{diag}},
      q|I<@diag> is filled|;
    ok !!keys %{$fn[0]{capabilities}},
      q|I<%capabilities> is filled|;
    FAF_show_message %{$fn[0]->{capabilities}};

    File::AptFetch::_uncache_configuration();
    undef @fn;      };

$units{one} = sub {
    $fn[0] = tempdir q|FAF_copy_one_XXXXXX|;
    $fn[1] = tempdir q|FAF_copy_one_XXXXXX|;
    $fn[4] = ( tempfile q|copy-one_XXXXXX|, DIR => $fn[0] )[1];
    FAF_wrap_stderr $fn[4];
    $fn[2] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|copy|;
    $fn[9] = FAF_unwrap_stderr $fn[4];
    ok !$fn[9], q|I<STDERR> is empty|;

    @fn[5,6] = tempfile q|copy_one_XXXXXX|, DIR => $fn[0];
    print { $fn[5] } q|copy one alpha|;
    close $fn[5];
    sleep 2;
    $fn[6] = join '/', cwd, $fn[6];
    $fn[7] = ( tempfile q|copy_one_XXXXXX|, DIR => $fn[0] )[1];
    $fn[7] = join '/', cwd, $fn[7];
    unlink $fn[7];
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[7,6];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[3],
        status => $fn[2]{Status},
        log    => $fn[2]{log}, },
      { rc     => '',
        status => 100,
        log    => [ ], },
      q|C<copy> accepts request for in directory copy|;
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::gain, $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[3],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[6]|,
        size   => -s $fn[6], },
      q|B<&gain> succeedes while requested file isn't gained|;
    like
      $fn[2]{message}{q|last-modified|},
      qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
      q|I<$message{Last-Modified}> seems to be OK|;
    $fn[8] = $fn[2]{message}{q|last-modified|},
    $fn[3] = FAF_wait_and_gain $fn[2];
# XXX:20090509024202:whynot: If I<$message{md5-hash}> happens to be 0 or empty space...
    $Copy_Has_Md5hash = $fn[2]{message}{q|md5-hash|};
    is_deeply
      { rc       => $fn[3],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[7],
        uri      => qq|copy:$fn[6]|,
        md5hash  => $Copy_Has_Md5hash && q|bb0d3ea842422fc60f85d8e8f6ebf7ab|,
        size     => -s $fn[7], },
      q|B<&gain> succeedes again|;
    ok -f $fn[7], q|and file is really copied|;
    like
      $fn[2]{message}{q|last-modified|},
      qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
      q|I<$message{Last-Modified}> seems to be OK|;
    is
      $fn[2]{message}{q|last-modified|}, $fn[8], q|mtimes are reported equal|;
    is +(stat $fn[6])[9], (stat $fn[7])[9], q|and mtimes are the same|;

    @fn[5,6] = tempfile q|copy_one_XXXXXX|, DIR => $fn[0];
    $fn[6] = join '/', cwd, $fn[6];
    print { $fn[5] } q|copy one bravo|;
    close $fn[5];
    sleep 2;
    $fn[7] = ( tempfile q|copy_one_XXXXXX|, DIR => $fn[1] )[1];
    $fn[7] = join '/', cwd, $fn[7];
    unlink $fn[7];
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[7,6];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc      => $fn[3],
        status  => $fn[2]{Status},
        log     => $fn[2]{log},
        md5hash => $fn[2]{message}{q|md5-hash|}, },
      { rc      => '',
        status  => 201,
        log     => [ ],
        md5hash => $Copy_Has_Md5hash && q|bb0d3ea842422fc60f85d8e8f6ebf7ab|,
                                                                            },
      q|C<copy> accepts request for inter directory copy|;
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::gain, $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[3],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[6]|,
        size   => -s $fn[6], },
      q|B<&gain> succeedes yet again while requested file isn't gained|;
    like
      $fn[2]{message}{q|last-modified|},
      qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
      q|I<$message{Last-Modified}> seems to be OK|;
    $fn[8] = $fn[2]{message}{q|last-modified|},
    $fn[3] = FAF_wait_and_gain $fn[2];
    is_deeply
      { rc       => $fn[3],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[7],
        uri      => qq|copy:$fn[6]|,
        md5hash  => $Copy_Has_Md5hash && q|1c0607dcd86a78ed1e30c894d0862a75|,
        size     => -s $fn[7], },
      q|B<&gain> succeedes yet again|;
    ok -f $fn[7], q|and file is really copied|;
    like
      $fn[2]{message}{q|last-modified|},
      qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
      q|I<$message{Last-Modified}> seems to be OK|;
    is
      $fn[2]{message}{q|last-modified|}, $fn[8], q|mtimes are reported equal|;
    is +(stat $fn[6])[9], (stat $fn[7])[9], q|and mtimes are the same|;

    $fn[9] = FAF_fetch_stderr $fn[4];
    ok !$fn[9], q|and I<STDERR> is emtpy|;

# FIXME: Find the way to check for inter device copy

    FAF_clean_up $fn[1];
    FAF_clean_up $fn[0];
    rmdir $fn[1];
    rmdir $fn[0];
    File::AptFetch::_uncache_configuration();
    undef @fn;     };

$units{two} = sub {
    $fn[0] = tempdir q|FAF_copy_two_XXXXXX|;
    $fn[1] = tempdir q|FAF_copy_two_XXXXXX|;
    $fn[4] = ( tempfile q|copy-two_XXXXXX|, DIR => $fn[0] )[1];
    FAF_wrap_stderr $fn[4];
    $fn[2] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|copy|;
    $fn[11] = FAF_unwrap_stderr $fn[4];
    ok !$fn[11], q|I<STDERR> is empty|;

    @fn[5,6] = tempfile q|copy_two_XXXXXX|, DIR => $fn[0];
    print { $fn[5] } q|copy two alpha|;
    close $fn[5];
    $fn[6] = join '/', cwd, $fn[6];
    @fn[5,7] = tempfile q|copy_two_XXXXXX|, DIR => $fn[0];
    print { $fn[5] } q|copy two bravo|;
    close $fn[5];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = ( tempfile q|copy_two_XXXXXX|, DIR => $fn[0] )[1];
    $fn[8] = join '/', cwd, $fn[8];
    unlink $fn[8];
    $fn[9] = ( tempfile q|copy_two_XXXXXX|, DIR => $fn[0] )[1];
    $fn[9] = join '/', cwd, $fn[9];
    unlink $fn[9];
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,6,9,7];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[3],
        status => $fn[2]{Status},
        log    => $fn[2]{log}, },
      { rc     => '',
        status => 100,
        log    => [ ], },
      q|C<copy> accepts two requests for in directory copy|;
    $fn[3] = FAF_wait_and_gain $fn[2];
    $fn[3] = FAF_wait_and_gain $fn[2];
    is_deeply
      { rc       => $fn[3],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        $fn[2]{message}{uri} eq qq|copy:$fn[6]| ?
          ( filename => $fn[8],
            uri      => qq|copy:$fn[6]|,
            md5hash  => $Copy_Has_Md5hash && q|5111cad44ab3f7285cbacfadba834811|,
            size     => -s $fn[6] )             :
        $fn[2]{message}{uri} eq qq|copy:$fn[7]| ?
          ( filename => $fn[9],
            uri      => qq|copy:$fn[7]|,
            md5hash  => $Copy_Has_Md5hash && q|a484a364925091b4e7b575b89740cb90|,
            size     => -s $fn[7] )             :
        ( ) },
      q|B<&gain> succeedes once|;
    $fn[10] = $fn[2]{message}{q|md5-hash|} || $fn[2]{message}{filename};
    $fn[3] = FAF_wait_and_gain $fn[2];
    $fn[3] = FAF_wait_and_gain $fn[2];
    is_deeply
      { rc       => $fn[3],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        $fn[2]{message}{uri} eq qq|copy:$fn[6]| ?
          ( filename => $fn[8],
            uri      => qq|copy:$fn[6]|,
            md5hash  => $Copy_Has_Md5hash && q|5111cad44ab3f7285cbacfadba834811|,
            size     => -s $fn[6] )             :
        $fn[2]{message}{uri} eq qq|copy:$fn[7]| ?
          ( filename => $fn[9],
            uri      => qq|copy:$fn[7]|,
            md5hash  => $Copy_Has_Md5hash && q|a484a364925091b4e7b575b89740cb90|,
            size     => -s $fn[7] )             :
        ( ) },
      q|B<&gain> succeedes twice|;
    isnt
      $fn[2]{message}{q|md5-hash|} || $fn[2]{message}{filename},
      $fn[10],
      q|and those files differ|;
    ok -f $fn[8], q|first file is really copied|;
    ok -f $fn[9], q|second file is really copied|;

    @fn[5,6] = tempfile q|copy_two_XXXXXX|, DIR => $fn[0];
    print { $fn[5] } q|copy two charlie|;
    close $fn[5];
    $fn[8] = ( tempfile q|copy_two_XXXXXX|, DIR => $fn[1] )[1];
    unlink $fn[8];
    $fn[6] = join '/', cwd, $fn[6];
    $fn[8] = join '/', cwd, $fn[8];
    @fn[5,7] = tempfile q|copy_two_XXXXXX|, DIR => $fn[1];
    print { $fn[5] } q|copy two delta|;
    close $fn[5];
    $fn[9] = ( tempfile q|copy_two_XXXXXX|, DIR => $fn[0] )[1];
    unlink $fn[9];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[9] = join '/', cwd, $fn[9];
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,6];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[3],
        status => $fn[2]{Status},
        log    => $fn[2]{log}, },
      { rc     => '',
        status => 201,
        log    => [ ], },
      q|C<copy> 1st accepts request for inter directory copy|;
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[9,7];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[3],
        status => $fn[2]{Status},
        log    => $fn[2]{log}, },
      { rc     => '',
        status => 201,
        log    => [ ], },
      q|C<copy> 2nd accepts request for inter directory copy|;
    $fn[3] = FAF_wait_and_gain $fn[2];
    $fn[3] = FAF_wait_and_gain $fn[2];
    is $fn[2]{Status}, 201, q|I<$Status> is 201|;
    is_deeply
      { rc       => $fn[3],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        $fn[2]{message}{uri} eq qq|copy:$fn[6]| ?
          ( filename => $fn[8],
            uri      => qq|copy:$fn[6]|,
            md5hash  => $Copy_Has_Md5hash && q|b0f81a7ab3506710399d06b2d9e00ddb|,
            size     => -s $fn[6] )             :
        $fn[2]{message}{uri} eq qq|copy:$fn[7]| ?
          ( filename => $fn[9],
            uri      => qq|copy:$fn[7]|,
            md5hash  => $Copy_Has_Md5hash && q|9a18605db9a2cdcddb8c5b9da163d485|,
            size     => -s $fn[7] )             :
        ( ) },
      q|B<&gain> succeedes once again|;
    $fn[10] = $fn[2]{message}{q|md5-hash|} || $fn[2]{message}{uri};
    $fn[3] = FAF_wait_and_gain $fn[2];
    $fn[3] = FAF_wait_and_gain $fn[2];
    is $fn[2]{Status}, 201, q|I<$Status> is 201|;
    is_deeply
      { rc       => $fn[3],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        $fn[2]{message}{uri} eq qq|copy:$fn[6]| ?
          ( filename => $fn[8],
            uri      => qq|copy:$fn[6]|,
            md5hash  => $Copy_Has_Md5hash && q|b0f81a7ab3506710399d06b2d9e00ddb|,
            size     => -s $fn[6] )             :
        $fn[2]{message}{uri} eq qq|copy:$fn[7]| ?
          ( filename => $fn[9],
            uri      => qq|copy:$fn[7]|,
            md5hash  => $Copy_Has_Md5hash && q|9a18605db9a2cdcddb8c5b9da163d485|,
            size     => -s $fn[7] )             :
        ( ) },
      q|B<&gain> succeedes twice again|;
    isnt
      $fn[2]{message}{q|md5-hash|} || $fn[2]{message}{uri},
      $fn[10],
      q|and those files differ|;
    ok -f $fn[8], q|third file is really copied|;
    ok -f $fn[9], q|fourth file is really copied|;

    $fn[11] = FAF_fetch_stderr $fn[4];
    ok !$fn[11], q|and I<STDERR> is empty|;

    FAF_clean_up $fn[1];
    FAF_clean_up $fn[0];
    rmdir $fn[1];
    rmdir $fn[0];
    File::AptFetch::_uncache_configuration();
    undef @fn;     };

$units{fail} = sub {
    $fn[0] = tempdir q|FAF_copy_fail_XXXXXX|;
    $fn[1] = tempdir q|FAF_copy_fail_XXXXXX|;
    $fn[5] = ( tempfile q|file-fail_XXXXXX|, DIR => $fn[0] )[1];
    FAF_wrap_stderr $fn[5];
    $fn[2] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|copy|;
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|file|;
    $fn[10] = FAF_unwrap_stderr $fn[5];
    ok !$fn[10], q|I<STDERR> is empty|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy fail alpha|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    FAF_show_message %{$fn[3]->{message}};
    $fn[9] = $fn[3]{message};
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => $fn[9]{size}, },
      q|B<&request> succeedes with self overwrite|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[4],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[7],
        uri      => qq|copy:$fn[7]|,
        size     => $fn[9]{size}, },
      q|B<&gain> succeedes again|;
    ok -f $fn[7], q|requested file is here|;
    TODO: {
        local $TODO = q|running modern APT|;
        is -s $fn[7], $fn[9]{size}, q|indeed|;
        is $fn[2]{message}{q|md5-hash|}, $fn[9]{q|md5-hash|},
          q|C<copy:> doesn't overwrite|
    }
    is
      $fn[2]{message}{q|last-modified|},
      $fn[9]{q|last-modified|},
      q|and mtime is the same|;
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    FAF_show_message %{$fn[3]->{message}};
    is
      $fn[2]{message}{q|last-modified|},
      $fn[3]{message}{q|last-modified|},
      q|and is actual one|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy fail bravo|;
    close $fn[6];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    unlink $fn[8];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    FAF_show_message %{$fn[3]->{message}};
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri}, },
      { rc     => '',
        status => 400,
        log    => [ ],
        uri    => qq|copy:$fn[7]|, },
      q|B<&request> fails with unabsolute uri|;
    isnt
      $fn[2]{message}{message},
      $fn[3]{message}{message},
      q|and the I<$message{Message}> differs though|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy fail charlie|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    unlink $fn[8];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes with unabsolute filename though|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[4],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[8],
        uri      => qq|copy:$fn[7]|,
        md5hash  => $Copy_Has_Md5hash && $fn[3]{message}{q|md5-hash|},
        size     => $fn[3]{message}{size}, },
      q|B<&gain> succeedes too|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy fail delta|;
    close $fn[6];
    $fn[7] = join '/', '', cwd, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    unlink $fn[8];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    FAF_show_message %{$fn[3]->{message}};
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri}, },
      { rc     => '',
        status => 400,
        log    => [ ],
        uri    => qq|copy:$fn[7]|, },
      q|B<&request> fails for double slash uri|;
    isnt
      $fn[2]{message}{message},
      $fn[3]{message}{message},
      q|and I<$message{Message}> differ again|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy fail echo|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = join
      '/', '', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    unlink $fn[8];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes for leading double slashed filename though|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[4],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[8],
        uri      => qq|copy:$fn[7]|,
        md5hash  => $Copy_Has_Md5hash && $fn[3]{message}{q|md5-hash|},
        size     => $fn[3]{message}{size}, },
      q|B<&gain> succeedes too|;

    $fn[10] = FAF_fetch_stderr $fn[5];
    ok !$fn[10], q|and I<STDERR> is empty|;

    FAF_clean_up $fn[1];
    FAF_clean_up $fn[0];
    rmdir $fn[1];
    rmdir $fn[0];
    File::AptFetch::_uncache_configuration();
    undef @fn;      };

$units{perm} = sub {
    $fn[0] = tempdir q|FAF_copy_fail_XXXXXX|;
    $fn[1] = tempdir q|FAF_copy_fail_XXXXXX|;
    $fn[5] = ( tempfile q|copy-perm_XXXXXX|, DIR => $fn[0] )[1];
    FAF_wrap_stderr $fn[5];
    $fn[12] = umask;
    umask 0072;
    $fn[2] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|copy|;
    umask $fn[12];
    $fn[3] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|file|;
    $fn[11] = FAF_unwrap_stderr $fn[5];
    ok !$fn[11], q|I<STDERR> is empty|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm alpha|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    chmod 0764, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    chmod 0777, $fn[8];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    FAF_show_message %{$fn[3]->{message}};
    $fn[9] = $fn[3]{message};
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes to overwrite regular file|;
    $fn[10] = $fn[2]{message};
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[4],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[8],
        uri      => qq|copy:$fn[7]|,
        md5hash  => $Copy_Has_Md5hash && $fn[9]{q|md5-hash|},
        size     => $fn[9]{size}, },
      q|B<&gain> succeedes then|;
    is -s $fn[8], $fn[9]{size}, q|have size|;
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[8,8];
    $fn[4] = FAF_wait_and_gain $fn[3];
    FAF_show_message %{$fn[3]->{message}};
    is
      $fn[9]{q|last-modified|},
      $fn[3]{message}{q|last-modified|},
      q|mtime is the same|;
    is $fn[9]{size}, $fn[3]{message}{size}, q|size is the same|;
    is $fn[9]{q|md5-hash|}, $fn[3]{message}{q|md5-hash|}, q|MD5 is the same|;
    isnt
      +(stat $fn[8])[2],
      (stat $fn[7])[2],
      q|source's permissions aren't passed|;
    TODO: {
        local $TODO = q|running modern APT|;
    is
      +(stat $fn[8])[2] & 0777, 0604, q|target's permissions are affected by umask|;
    }

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm bravo|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    chmod 0000, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    unlink $fn[8];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes to retrieve unreadable file|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri}, },
      { rc     => '',
        status => 400,
        log    => [ ],
        uri    => qq|copy:$fn[7]|, },
      q|B<&gain> fails then|;
    TODO: {
        local $TODO = q|running modern APT|;
        like $fn[2]{message}{message}, qr{\bpermission}i,
          q|message is enough|;
    ok -f $fn[8], q|target is created|;
        is -s _, 0, q|and no size|;
    }

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm charlie|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    chmod 0000, $fn[8];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes to overwrite unwritable file|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    TODO: {
        local $TODO = q|running modern APT|;
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        uri    => qq|copy:$fn[7]|, },
      q|B<&gain> fails then|;
    ok !$fn[2]{message}{message}, q|and I<$message{Message}> is unset|;
    is +((stat $fn[8])[2] & 0777), 0604, q|and permissions are overriden|;
    }

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm delta|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    chmod 0333, $fn[0];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes with unreadable source directory|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    chmod 0755, $fn[0];
    is_deeply
      { rc       => $fn[4],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[8],
        uri      => qq|copy:$fn[7]|,
        md5hash  => $Copy_Has_Md5hash && $fn[3]{message}{q|md5-hash|},
        size     => $fn[3]{message}{size}, },
      q|B<&gain> succeedes then|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm echo|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    unlink $fn[8];
    chmod 0555, $fn[1];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes with unwritable target directory|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    chmod 0755, $fn[1];
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri}, },
      { rc     => '',
        status => 400,
        log    => [ ],
        uri    => qq|copy:$fn[7]|, },
      q|B<&gain> fails then|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm foxtrot|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[3], @fn[7,7];
    $fn[4] = FAF_wait_and_gain $fn[3];
    chmod 0555, $fn[1];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes with unwritable target directory but file present|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    chmod 0755, $fn[1];
    TODO: {
        local $TODO = q|running modern APT|;
    is_deeply
      { rc       => $fn[4],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        uri      => $fn[2]{message}{uri}, },
      { rc       => '',
        status   => 400,
        log      => [ ],
        uri      => qq|copy:$fn[7]|, },
      q|B<&gain> fails then|;
        like $fn[2]{message}{message}, qr{\bpermission}i,
          q|message is enough|;
    }

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm gala|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    chmod 0666, $fn[0];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri}, },
      { rc     => '',
        status => 400,
        log    => [ ],
        uri    => qq|copy:$fn[7]|, },
      q|B<&request> fails with unseekable source directory|;
    chmod 0755, $fn[0];

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm hotel|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    unlink $fn[8];
    chmod 0666, $fn[1];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes with unseekable target directory|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    chmod 0755, $fn[1];
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri}, },
      { rc     => '',
        status => 400,
        log    => [ ],
        uri    => qq|copy:$fn[7]|, },
      q|B<&gain> fails then|;

    @fn[6,7] = tempfile q|copy_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[6] } q|copy perm india|;
    close $fn[6];
    $fn[7] = join '/', cwd, $fn[7];
    $fn[8] = join
      '/', cwd, ( tempfile q|copy_fail_XXXXXX|, DIR => $fn[1] )[1];
    chmod 0666, $fn[1];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[8,7];
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri},
        size   => $fn[2]{message}{size}, },
      { rc     => '',
        status => 200,
        log    => [ ],
        uri    => qq|copy:$fn[7]|,
        size   => -s $fn[7], },
      q|B<&request> succeedes with unseekable target directory but file present|;
    $fn[4] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    chmod 0755, $fn[1];
    is_deeply
      { rc     => $fn[4],
        status => $fn[2]{Status},
        log    => $fn[2]{log},
        uri    => $fn[2]{message}{uri}, },
      { rc     => '',
        status => 400,
        log    => [ ],
        uri    => qq|copy:$fn[7]|, },
      q|B<&gain> fails then|;

    $fn[11] = FAF_fetch_stderr $fn[5];
    ok !$fn[11], q|and I<STDERR> is empty|;

    FAF_clean_up $fn[1];
    FAF_clean_up $fn[0];
    rmdir $fn[1];
    rmdir $fn[0];
    File::AptFetch::_uncache_configuration();
    undef @fn;      };

our @units = ( qw| void one two fail perm | );

t::TestSuite::FAF_do_units @ARGV;

# vim: syntax=perl
