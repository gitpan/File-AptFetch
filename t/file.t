#!/usr/bin/perl
# $Id: file.t 431 2010-12-05 01:07:42Z whynot $

use strict;
use warnings;

package main;
use version 0.50; our $VERSION = qv q|0.0.8|;

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

$fn[0] = t::TestSuite::FAF_discover_lib;
plan
  !defined $fn[0]                               ?
    (skip_all => q|not *nix, or misconfigured|) :
  !$fn[0]                                       ?
    (skip_all => q|not Debian, or alike|)       :
  !-x qq|$fn[0]/file|                           ?
    (skip_all => q|missing method (copy)|)      :
    (tests    => 40);
undef @fn;

$units{void} = sub {
    $fn[0] = File::AptFetch->init(q|file|);
    isa_ok $fn[0], q|File::AptFetch|,
      q|C<file> method initializes|;
    is $fn[0]{Status}, 100,
      q|C<file> method is ready|;
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
    $fn[0] = tempdir q|FAF_file_one_XXXXXX|;
    $fn[2] = ( tempfile q|file-one_XXXXXX|, DIR => $fn[0] )[1];
    FAF_wrap_stderr $fn[2];
    $fn[1] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|file|;
    $fn[6] = FAF_unwrap_stderr $fn[2];
    ok !$fn[6], q|I<STDERR> is empty|;

    @fn[3,4] = tempfile q|file_one_XXXXXX|, DIR => $fn[0];
    print { $fn[3] } q|file one alpha|;
    close $fn[3];
    $fn[4] = join '/', cwd, $fn[4];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::request, $fn[1], @fn[4,4];
    is_deeply
      { rc     => $fn[5],
        status => $fn[1]{Status},
        log    => $fn[1]{log}, },
      { rc     => '',
        status => 100,
        log    => [ ], },
      q|C<file> accepts request|;
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::gain, $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc       => $fn[5],
        status   => $fn[1]{Status},
        log      => $fn[1]{log},
        filename => $fn[1]{message}{filename},
        uri      => $fn[1]{message}{uri},
        md5hash  => $fn[1]{message}{q|md5-hash|},
        size     => $fn[1]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[4],
        uri      => qq|file:$fn[4]|,
        md5hash  => q|5eb986e6affbe6f32f88638e7e3af63d|,
        size     => -s $fn[4], },
      q|B<&gain> succeedes|;
    like
      $fn[1]{message}{q|last-modified|},
      qr(\d{1,2} \w{3} \d{4} [0-9:]{8}),
      q|I<$message{Last-Modified}> seems to be OK|;
    $fn[5] = FAF_wait_and_gain $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc      => $fn[5],
        status  => $fn[1]{Status},
        md5hash => $fn[1]{message}{q|md5-hash|}, },
      { rc => q|(file): timeouted without responce|,
        status  => 201,
        md5hash => q|5eb986e6affbe6f32f88638e7e3af63d|, },
      q|then timeouts|;
    @fn[3,4] = tempfile q|file_one_XXXXXX|, DIR => $fn[0];
    print { $fn[3] } q|file one bravo|;
    close $fn[3];
    $fn[4] = join '/', cwd, $fn[4];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::request, $fn[1], @fn[4,4];
    $fn[5] = FAF_wait_and_gain $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc       => $fn[5],
        status   => $fn[1]{Status},
        log      => $fn[1]{log},
        filename => $fn[1]{message}{filename},
        uri      => $fn[1]{message}{uri},
        md5hash  => $fn[1]{message}{q|md5-hash|},
        size     => $fn[1]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[4],
        uri      => qq|file:$fn[4]|,
        md5hash  => q|2ee638f0f7595b7ea01f3c0edcf45f54|,
        size     => -s $fn[4], },
      q|then recovers|;
    $fn[6] = FAF_fetch_stderr $fn[2];
    ok !$fn[6], q|and I<STDERR> is empty|;

    FAF_clean_up $fn[0];
    rmdir $fn[0];
    File::AptFetch::_uncache_configuration();
    undef @fn; };

$units{two} = sub {
    $fn[0] = tempdir q|FAF_file_two_XXXXXX|;
    $fn[2] = ( tempfile q|file-two_XXXXXX|, DIR => $fn[0] )[1];
    FAF_wrap_stderr $fn[2];
    $fn[1] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|file|;
    $fn[8] = FAF_unwrap_stderr $fn[2];
    ok !$fn[8], q|I<STDERR> is empty|;

    @fn[3,4] = tempfile q|file_two_XXXXXX|, DIR => $fn[0];
    print { $fn[3] } q|file two alpha|;
    close $fn[3];
    @fn[3,5] = tempfile q|file_two_XXXXXX|, DIR => $fn[0];
    print { $fn[3] } q|file two bravo|;
    close $fn[3];
    $fn[4] = join '/', cwd, $fn[4];
    $fn[5] = join '/', cwd, $fn[5];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[1], @fn[4,4];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[1], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[1]{Status},
        log      => $fn[1]{log},
        filename => $fn[1]{message}{filename},
        uri      => $fn[1]{message}{uri},
        md5hash  => $fn[1]{message}{q|md5-hash|},
        size     => $fn[1]{message}{size}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        !index($fn[1]{message}{q|md5-hash|}, q|5b17|) ?
          ( filename => $fn[4],
            uri      => qq|file:$fn[4]|,
            md5hash  => q|5b17fdef964d9b01f2e6e595fb0034b7|,
            size     => -s $fn[4], )                  :
        !index($fn[1]{message}{q|md5-hash|}, q|0e31|) ?
          ( filename => $fn[5],
            uri      => qq|file:$fn[5]|,
            md5hash  => q|0e3186ccab6bc750fd707b159875e596|,
            size     => -s $fn[5], )                  :
          ( ) },
      q|B<&gain> succeedes once|;
    $fn[7] = $fn[1]{message}{q|md5-hash|};
    $fn[6] = FAF_wait_and_gain $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[1]{Status},
        log      => $fn[1]{log},
        filename => $fn[1]{message}{filename},
        uri      => $fn[1]{message}{uri},
        md5hash  => $fn[1]{message}{q|md5-hash|},
        size     => $fn[1]{message}{size}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        !index($fn[1]{message}{q|md5-hash|}, q|5b17|) ?
          ( filename => $fn[4],
            uri      => qq|file:$fn[4]|,
            md5hash  => q|5b17fdef964d9b01f2e6e595fb0034b7|,
            size     => -s $fn[4], )                  :
        !index($fn[1]{message}{q|md5-hash|}, q|0e31|) ?
          ( filename => $fn[5],
            uri      => qq|file:$fn[5]|,
            md5hash  => q|0e3186ccab6bc750fd707b159875e596|,
            size     => -s $fn[5], )                  :
          ( ) },
      q|B<&gain> succeedes twice|;
    isnt
      $fn[1]{message}{q|md5-hash|}, $fn[7], q|retrieved files are different|;
    @fn[3,4] = tempfile q|file_two_XXXXXX|, DIR => $fn[0];
    print { $fn[3] } q|file two charlie|;
    close $fn[3];
    @fn[3,5] = tempfile q|file_two_XXXXXX|, DIR => $fn[0];
    print { $fn[3] } q|file two delta|;
    close $fn[3];
    $fn[4] = join '/', cwd, $fn[4];
    $fn[5] = join '/', cwd, $fn[5];
    $fn[6] = FAF_safe_wrapper
      \&File::AptFetch::request, $fn[1], @fn[4,4], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[1]{Status},
        log      => $fn[1]{log},
        filename => $fn[1]{message}{filename},
        uri      => $fn[1]{message}{uri},
        md5hash  => $fn[1]{message}{q|md5-hash|},
        size     => $fn[1]{message}{size}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        !index($fn[1]{message}{q|md5-hash|}, q|0f59|) ?
          ( filename => $fn[4],
            uri      => qq|file:$fn[4]|,
            md5hash  => q|0f59302257116cc357cdee1d02687c41|,
            size     => -s $fn[4] )                   :
        !index($fn[1]{message}{q|md5-hash|}, q|2cdf|) ?
          ( filename => $fn[5],
            uri      => qq|file:$fn[5]|,
            md5hash  => q|2cdfe7217d54310df2caebcd0df8b124|,
            size     => -s $fn[5] )                   :
          ( ) },
      q|B<&gain> succeedes once yet|;
    $fn[7] = $fn[1]{message}{q|md5-hash|};
    $fn[6] = FAF_wait_and_gain $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[1]{Status},
        log      => $fn[1]{log},
        filename => $fn[1]{message}{filename},
        uri      => $fn[1]{message}{uri},
        md5hash  => $fn[1]{message}{q|md5-hash|},
        size     => $fn[1]{message}{size}, },
      { rc     => '',
        status => 201,
        log    => [ ],
        !index($fn[1]{message}{q|md5-hash|}, q|0f59|) ?
          ( filename => $fn[4],
            uri      => qq|file:$fn[4]|,
            md5hash  => q|0f59302257116cc357cdee1d02687c41|,
            size     => -s $fn[4] )                   :
        !index($fn[1]{message}{q|md5-hash|}, q|2cdf|) ?
          ( filename => $fn[5],
            uri      => qq|file:$fn[5]|,
            md5hash  => q|2cdfe7217d54310df2caebcd0df8b124|,
            size     => -s $fn[5] )                   :
          ( ) },
      q|B<&gain> succeedes twice yet|;
    isnt
      $fn[1]{message}{q|md5-hash|}, $fn[7], q|retrieved files are different|;
    $fn[7] = $fn[1]{message}{q|md5-hash|};
    $fn[5] = FAF_wait_and_gain $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc      => $fn[5],
        status  => $fn[1]{Status},
        md5hash => $fn[1]{message}{q|md5-hash|}, },
      { rc      => q|(file): timeouted without responce|,
        status  => 201,
        md5hash => $fn[7], },
      q|then timeouts|;
    @fn[3,4] = tempfile q|file_two_XXXXXX|, DIR => $fn[0];
    print { $fn[3] } q|file two echo|;
    close $fn[3];
    $fn[4] = join '/', cwd, $fn[4];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[1], @fn[4,4];
    $fn[6] = FAF_wait_and_gain $fn[1];
    FAF_show_message %{$fn[1]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[1]{Status},
        log      => $fn[1]{log},
        filename => $fn[1]{message}{filename},
        uri      => $fn[1]{message}{uri},
        md5hash  => $fn[1]{message}{q|md5-hash|},
        size     => $fn[1]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[4],
        uri      => qq|file:$fn[4]|,
        md5hash  => q|ee1a9331bbcdb86687a484a7e0583201|,
        size     => -s $fn[4], },
      q|then recovers|;
    $fn[8] = FAF_fetch_stderr $fn[2];
    ok !$fn[8], q|and I<STDERR> is empty|;

    FAF_clean_up $fn[0];
    rmdir $fn[0];
    File::AptFetch::_uncache_configuration();
    undef @fn; };

$units{fail} = sub {
    $fn[0] = tempdir q|FAF_file_fail_XXXXXX|;
    $fn[1] = tempdir q|FAF_file_fail_XXXXXX|;
    $fn[3] = ( tempfile q|file-fail_XXXXXX|, DIR => $fn[0] )[1];
    FAF_wrap_stderr $fn[3];
    $fn[2] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|file|;
    $fn[8] = FAF_unwrap_stderr $fn[3];
    ok !$fn[8], q|I<STDERR> is emtpy|;

    @fn[4,5] = tempfile q|file_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[4] } q|file fail alpha|;
    close $fn[4];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 400,
        log      => [ ],
        filename => undef,
        uri      => qq|file:$fn[5]|,
        md5hash  => undef,
        size     => undef, },
      q|fails with unabsolute uri|;
    ok $fn[2]{message}{message}, q|I<$message{Message}> is set|;

    $fn[4] = join '/', cwd, $fn[1], q|..|, $fn[5];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[4,4];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[4],
        uri      => qq|file:$fn[4]|,
        md5hash  => q|32ab06696a9904ea7e3790b1acf8fc5d|,
        size     => -s $fn[4], },
      q|relative uri succeedes though|;

    $fn[5] = ( tempfile q|file_fail_XXXXXX|, DIR => $fn[0] )[1];
    unlink $fn[5];
    $fn[5] = join '/', cwd, $fn[5];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 400,
        log      => [ ],
        filename => undef,
        uri      => qq|file:$fn[5]|,
        md5hash  => undef,
        size     => undef, },
      q|fails with unlocatable uri|;
    ok $fn[2]{message}{message}, q|I<$message{Message}> is set|;

    @fn[4,5] = tempfile q|file_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[4] } q|file fail bravo|;
    close $fn[4];
    chmod 0000, $fn[5];
    $fn[5] = join '/', cwd, $fn[5];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[5],
        uri      => qq|file:$fn[5]|,
        md5hash  => $t::TestSuite::Empty_MD5,
        size     => -s $fn[5], },
      q|succeedes with unreadable uri|;

    $fn[5] = join '/', '', cwd, $fn[5];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 400,
        log      => [ ],
        filename => undef,
        uri      => qq|file:$fn[5]|,
        md5hash  => undef,
        size     => undef, },
      q|then fails with leading-double-slash uri|;
    ok $fn[2]{message}{message}, q|I<$message{Message}> is set|;
    $fn[7] = $fn[2]{message}{message};

    @fn[4,5] = tempfile q|file_fail_XXXXXX|, DIR => $fn[0];
    print { $fn[4] } q|file fail charlie|;
    close $fn[4];
    $fn[5] = join '/', '', cwd, $fn[5];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 400,
        log      => [ ],
        filename => undef,
        uri      => qq|file:$fn[5]|,
        md5hash  => undef,
        size     => undef, },
      q|fails with leading-double-slash uri|;
    ok $fn[2]{message}{message}, q|I<$message{Message}> is set|;
    isnt
      $fn[2]{message}{message},
      $fn[7],
      q|and I<$message{Message}> differs with previous|;

    $fn[5] = join '/', cwd, $fn[0];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[5],
        uri      => qq|file:$fn[5]|,
        md5hash  => $t::TestSuite::Empty_MD5,
# XXX: Hmmm,..
        size     => -s $fn[5], },
      q|succeedes with directory|;

    $fn[5] = join '/', cwd, $fn[0], '';
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 201,
        log      => [ ],
        filename => $fn[5],
        uri      => qq|file:$fn[5]|,
        md5hash  => $t::TestSuite::Empty_MD5,
# XXX: Hmmm,..
        size     => -s $fn[5], },
      q|succeedes with trailing slash|;

    $fn[5] = join '/', '', cwd, $fn[0];
    $fn[6] = FAF_safe_wrapper \&File::AptFetch::request, $fn[2], @fn[5,5];
    $fn[6] = FAF_wait_and_gain $fn[2];
    FAF_show_message %{$fn[2]->{message}};
    is_deeply
      { rc       => $fn[6],
        status   => $fn[2]{Status},
        log      => $fn[2]{log},
        filename => $fn[2]{message}{filename},
        uri      => $fn[2]{message}{uri},
        md5hash  => $fn[2]{message}{q|md5-hash|},
        size     => $fn[2]{message}{size}, },
      { rc       => '',
        status   => 400,
        log      => [ ],
        filename => undef,
        uri      => qq|file:$fn[5]|,
        md5hash  => undef,
        size     => undef, },
      q|fails with leading-double-slash directory|;
    ok $fn[2]{message}{message}, q|I<$message{Message}> is set|;

    $fn[8] = FAF_fetch_stderr $fn[3];
    ok !$fn[8], q|and I<STDERR> is empty|;

    FAF_clean_up $fn[1];
    FAF_clean_up $fn[0];
    rmdir $fn[1];
    rmdir $fn[0];
    File::AptFetch::_uncache_configuration();
    undef @fn; };

our @units = ( qw| void one two fail | );

t::TestSuite::FAF_do_units @ARGV;

# vim: syntax=perl
