#!/usr/bin/perl
# $Id: void.t 12 2009-05-09 22:15:56Z whynot $

package main;
use strict;
use warnings;
use version 0.50;
use t::TestSuite qw|
  FAF_wrap_stderr FAF_unwrap_stderr FAF_safe_wrapper
  FAF_prepare_method
  FAF_clean_up                        |;
use File::AptFetch;
use File::AptFetch::ConfigData;
use Test::More;
use File::Temp   qw| tempfile tempdir |;

our $VERSION = qv q|0.0.8|;

my @fn;
our %units;

my $Apt_Lib = t::TestSuite::FAF_discover_lib;
plan
  !defined $Apt_Lib                             ?
    (skip_all => q|not *nix, or misconfigured|) :
    (tests    => 54);
unless($Apt_Lib)                                               {
    t::TestSuite::FAF_diag q|missing APT: workarounds enabled|; }

$units{handshake} = sub {
    $fn[0] = tempdir q|FAF_void_handshake_XXXXXX|;
    $fn[1] = File::AptFetch::ConfigData->config(q|lib_method|);
    $fn[2] = ( tempfile q|FAF_void-handshake_XXXXXX|, DIR => $fn[0] )[1];

    unless($Apt_Lib)                                                       {
        $fn[7] = File::AptFetch::ConfigData->config(q|config_source|);
        @fn[3,4] = tempfile q|config_void_handshake_XXXXXX|, DIR => $fn[0];
        FAF_prepare_method
            *{$fn[3]}, q|y-method|, $fn[2], qq|Dir::Bin::methods "$fn[0]";|;
        close $fn[3];
        File::AptFetch::ConfigData->set_config(config_source => [ $fn[4] ]);
                                                                            };

    $fn[5] = File::AptFetch->init;
    like
      $fn[5],
      qr{^I<method> is unspecified$}sm,
      q|F::AF->init fails with empty CL|;

    File::AptFetch::ConfigData->set_config(lib_method => q|/dev/null|);
    FAF_wrap_stderr $fn[2];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|void|;
    $fn[6] = FAF_unwrap_stderr $fn[2];
    like
      $fn[5],
      qr{^C<void>: \(\d+\): died without handshake}sm,
      q|F::AF->init fails with broken I<lib_method>|;

    File::AptFetch::ConfigData->set_config(lib_method => $fn[0]);
    FAF_wrap_stderr $fn[2];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|void|;
    $fn[6] = FAF_unwrap_stderr $fn[2];
    like
      $fn[5],
      qr{^C<void>: \(\d+\): died without handshake}sm,
      q|F::AF->init fails with empty I<lib_method>|;

    $fn[4] = (split
      qr{/}, ( tempfile q|void_handshake_XXXXXX|, DIR => $fn[0] )[1])[-1];
    FAF_wrap_stderr $fn[2];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[4];
    $fn[6] = FAF_unwrap_stderr $fn[2];
    like
      $fn[5],
      qr{^C<\Q$fn[4]\E>: \(\d+\): died without handshake}sm,
      q|F::AF->init fails with unexecutable method|;

    $fn[4] = ( tempfile q|void_handshake_XXXXXX|, DIR => $fn[0] )[1];
    chmod 0755, $fn[4];
    $fn[4] = (split qr{/}, $fn[4])[-1];
    FAF_wrap_stderr $fn[2];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[4];
    $fn[6] = FAF_unwrap_stderr $fn[2];
    like
      $fn[5],
      qr{^C<\Q$fn[4]\E>: timeouted without handshake}sm,
      q|F::AF->init fails with empty executable|;

    @fn[3,4] = tempfile q|void_handshake_XXXXXX|, DIR => $fn[0];
    FAF_prepare_method *{$fn[3]}, q|x-method|, $fn[2], q|25|;
    close $fn[3];
    $fn[4] = (split qr{/}, $fn[4])[-1];
    FAF_wrap_stderr $fn[2];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[4];
    $fn[6] = FAF_unwrap_stderr $fn[2];
    like
      $fn[5],
      qr{C<\Q$fn[4]\E>: timeouted without handshake}sm,
      q|F::AF->init fails with bogus executable|;

    File::AptFetch::_uncache_configuration;
    File::AptFetch::ConfigData->set_config(lib_method => undef);
    @fn[3,4] = tempfile q|void_handshake_XXXXXX|, DIR => $fn[0];
    FAF_prepare_method *{$fn[3]}, q|x-method|, $fn[2], q|3|;
    close $fn[3];
    $fn[4] = (split qr{/}, $fn[4])[-1];
    FAF_wrap_stderr $fn[2];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[4];
    $fn[6] = FAF_unwrap_stderr $fn[2];
    ok
      +File::AptFetch::ConfigData->config(q|lib_method|),
      q|F::AF->init sets I<lib_method>|;

    File::AptFetch::ConfigData->set_config(config_source => $fn[7])
      unless $Apt_Lib;
    File::AptFetch::ConfigData->set_config(lib_method => $fn[1]);
    File::AptFetch::_uncache_configuration;
    FAF_clean_up $fn[0];
    rmdir $fn[0];
    undef @fn;           };

$units{aptconfig} = sub {
    $fn[0] = tempdir q|FAF_void_aptconfig_XXXXXX|;
    $fn[1] = File::AptFetch::ConfigData->config(q|config_source|);
    $fn[2] = File::AptFetch::ConfigData->config(q|lib_method|);
    $fn[3] = ( tempfile q|FAF_void-aptconfig_XXXXXX|, DIR => $fn[0] )[1];

    File::AptFetch::ConfigData->set_config(
      config_source => [ qw| /dev/null | ]);
    FAF_wrap_stderr $fn[3];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|void|;
    $fn[5] = FAF_unwrap_stderr $fn[3];
    like
      $fn[4],
      qr{^C<void>: \(C<apt-config>\) died: \d+}sm,
      q|F::AF->init fails with broken I<config_source>|;

    @fn[6,7] = tempfile q|void_aptconfig_XXXXXX|, DIR => $fn[0];
    FAF_prepare_method *{$fn[6]}, q|x-method|, $fn[3], q|1|;
    close $fn[6];
    File::AptFetch::ConfigData->set_config(config_source => [ $fn[7] ]);
    FAF_wrap_stderr $fn[3];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|void|;
    $fn[5] = FAF_unwrap_stderr $fn[3];
    like
      $fn[4],
      qr{^C<void>: \(C<apt-config>\): failed to output anything}sm,
      q|F::AF->init fails with empty I<config_source>|;

    @fn[6,7] = tempfile q|void_aptconfig_XXXXXX|, DIR => $fn[0];
    FAF_prepare_method *{$fn[6]}, q|x-method|, $fn[3], q|25|;
    close $fn[6];
    File::AptFetch::ConfigData->set_config(config_source => [ $fn[7] ]);
    FAF_wrap_stderr $fn[3];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|void|;
    $fn[5] = FAF_unwrap_stderr $fn[3];
    like
      $fn[4],
      qr{^C<void>: \(C<apt-config>\): timeouted}sm,
      q|F::AF->init fails with slow I<config_source>|;

    File::AptFetch::ConfigData->set_config(lib_method => undef);

    foreach my $sample (
      q|!@#$ "xyz";|, q|$self|,
      q|ABC|, q|ABC |, q|ABC ";|, q|ABC ;|, q|ABC ""|,
      q|ABC"xyz";|, q|ABC "xyz"|, q|ABC "xyz;|, q|ABC "xyz"abc;|,
        q|ABC "xyz" ;|,
      q|ABC: "xyz";|, q|ABC::: "xyz";|,
      q| ABC "xyz";|,
      q|ABC::!@#$ "xyz";|,
      q|ABC ::def "xyz";|, q|ABC:: def "xyz";|,
      q|ABC::def: "xyz";|, q|ABC::def::: "xyz";|,
      q|ABC:def "xyz";|, q|ABC:::def "xyz";|, )             {
        @fn[6,7] = tempfile q|void_aptconfig_XXXXXX|, DIR => $fn[0];
        FAF_prepare_method *{$fn[6]}, q|y-method|, $fn[3], $sample;
        close $fn[6];
        File::AptFetch::ConfigData->set_config(config_source => [ $fn[7] ]);
        FAF_wrap_stderr $fn[3];
        $fn[4] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|void|;
        $fn[5] = FAF_unwrap_stderr $fn[3];
        like
          $fn[4],
          qr{^C<void>: \(\Q$sample\E\): that's unparsable}sm,
          qq|F::AF->init fails with broken entry ($sample)|; };

# FIXME: Unorthogonal.
    @fn[6,7] = tempfile q|void_aptconfig_XXXXXX|, DIR => $fn[0];
    FAF_prepare_method
      *{$fn[6]}, q|y-method|, $fn[3],
      q|ABC "";|, q|DEF "xyz";|,
      q|ABC::def "";|, q|GHI::jkl "xyz";|,
      q|ABC::def:: "";|, q|GHI::jkl:: "xyz";|,
      q|ABC::def:::: "";|, q|GHI::jkl:::: "xyz";|,
      q|MNO """;|, q|MNO "abc"xyz";|,
      q|PQR "abc xyz";|, q|PQR::stu "abc xyz";|;
    close $fn[6];
    File::AptFetch::ConfigData->set_config(config_source => [ $fn[7] ]);
    FAF_wrap_stderr $fn[3];
    $fn[4] = FAF_safe_wrapper \&File::AptFetch::init, q||, q|void|;
    $fn[5] = FAF_unwrap_stderr $fn[3];
    like
      $fn[4],
      qr{^C<void>: \(I<lib_method>\): neither preset nor found}sm,
      q|F::AF->init fails with missing I<lib_method>|;

    File::AptFetch::ConfigData->set_config(lib_method => $fn[2]);
    File::AptFetch::ConfigData->set_config(config_source => $fn[1]);
    File::AptFetch::_uncache_configuration;
    FAF_clean_up $fn[0];
    rmdir $fn[0];
    undef @fn;           };

$units{configure} = sub {
    $fn[0] = tempdir q|FAF_void_configure_XXXXXX|;
    $fn[1] = File::AptFetch::ConfigData->config(q|lib_method|);
    File::AptFetch::ConfigData->set_config(lib_method => $fn[0]);
    $fn[2] = ( tempfile q|FAF_void-configure_XXXXXX|, DIR => $fn[0] )[1];

    unless($Apt_Lib)                                                       {
        $fn[7] = File::AptFetch::ConfigData->config(q|config_source|);
        @fn[3,4] = tempfile q|config_void_configure_XXXXXX|, DIR => $fn[0];
        FAF_prepare_method
            *{$fn[3]},
            q|y-method|,
            $fn[2],
            qq|Dir "$fn[0]";|,
            qq|Dir::Etc "$fn[0]";|,
            qq|Dir::Bin::methods "$fn[0]";|,
            qq|APT::Architecture "foobar";|;
        close $fn[3];
        File::AptFetch::ConfigData->set_config(config_source => [ $fn[4] ]);
                                                                            };

    @fn[3,4] = tempfile q|void_configure_XXXXXX|, DIR => $fn[0];
    FAF_prepare_method *{$fn[3]}, q|x-method|, $fn[2], q|5|;
    close $fn[3];
    $fn[4] = (split qr{/}, $fn[4])[-1];
    FAF_wrap_stderr $fn[2];
    $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[4];
    $fn[6] = FAF_unwrap_stderr $fn[2];
    ok
      $fn[6] =~ m(^{Config-Item: Dir=\S+}$)m      &&
      $fn[6] =~ m(^{Config-Item: Dir::Etc=\S+}$)m &&
      $fn[6] =~ m(^{Config-Item: APT::Architecture=\S+}$)m,
      q|F::AF->init feeds a method with APT's configuration|;

    foreach my $sample (
      [ q|abc xyz|,   q|| ],
      [ q|1000 xyz|,  q|| ],
      [ q|10 xyz|,    q|| ],
      [ q|!@#$ xyz|,  q|| ],
      [ q|$self xyz|, q|| ], )                                    {
        @fn[3,4] = tempfile q|void_configure_XXXXXX|, DIR => $fn[0];
        FAF_prepare_method *{$fn[3]}, q|z-method|, $fn[2], @$sample;
        close $fn[3];
        $fn[4] = (split qr{/}, $fn[4])[-1];
        FAF_wrap_stderr $fn[2];
        $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[4];
        $fn[6] = FAF_unwrap_stderr $fn[2];
        like
          $fn[5],
          qr{^C<\Q$fn[4]\E>: \(\Q$sample->[0]\E\): that's not a Status Code$},
          qq|F::AF->init fails at broken greeting ($sample->[0])|; };

    foreach my $sample (
      [ q|100 Capabilities|, q|: xyz|,      q|| ],
      [ q|100 Capabilities|, q| : xyz|,     q|| ],
      [ q|100 Capabilities|, q|!@#$: xyz|,  q|| ],
      [ q|100 Capabilities|, q|$self: xyz|, q|| ],
      [ q|100 Capabilities|, q| abc: xyz|,  q|| ],
      [ q|100 Capabilities|, q|abc : xyz|,  q|| ],
      [ q|100 Capabilities|, q|abc:: xyz|,  q|| ],
      [ q|100 Capabilities|, q|abc xyz|,    q|| ],
      [ q|100 Capabilities|, q|abc:|,       q|| ],
      [ q|100 Capabilities|, q|abc: |,      q|| ],
      [ q|100 Capabilities|, q|abc:  |,     q|| ], )             {
        @fn[3,4] = tempfile q|void_configure_XXXXXX|, DIR => $fn[0];
        FAF_prepare_method *{$fn[3]}, q|z-method|, $fn[2], @$sample;
        close $fn[3];
        $fn[4] = (split qr{/}, $fn[4])[-1];
        FAF_wrap_stderr $fn[2];
        $fn[5] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[4];
        $fn[6] = FAF_unwrap_stderr $fn[2];
        like
          $fn[5],
          qr{^C<\Q$fn[4]\E>: \(\Q$sample->[1]\E\): that's not a Message$},
          qq|F::AF->init fails at broken message ($sample->[1])|; };

    File::AptFetch::ConfigData->set_config(source_config => $fn[7])
      unless $Apt_Lib;
    File::AptFetch::ConfigData->set_config(lib_method => $fn[1]);
    File::AptFetch::_uncache_configuration;
    FAF_clean_up $fn[0];
    rmdir $fn[0];
    undef @fn;           };

$units{destroy} = sub {
    $fn[0] = tempdir q|FAF_void_destroy_XXXXXX|;
    $fn[1] = File::AptFetch::ConfigData->config(q|lib_method|);
    File::AptFetch::ConfigData->set_config(lib_method => $fn[0]);
    $fn[3] = $fn[2] = File::AptFetch::ConfigData->config(q|signal|);
    $fn[4] = ( tempfile q|void-destroy_XXXXXX|, DIR => $fn[0] )[1];

    unless($Apt_Lib)                                                       {
        $fn[9] = File::AptFetch::ConfigData->config(q|config_source|);
        @fn[5,6] = tempfile q|config_void_handshake_XXXXXX|, DIR => $fn[0];
        FAF_prepare_method
            *{$fn[5]}, q|y-method|, $fn[2], qq|Dir::Bin::methods "$fn[0]";|;
        close $fn[5];
        File::AptFetch::ConfigData->set_config(config_source => [ $fn[6] ]);
                                                                            };

    @fn[5,6] = tempfile q|void_destroy_XXXXXX|, DIR => $fn[0];
    FAF_prepare_method *{$fn[5]}, q|w-method|, $fn[4];
    close $fn[5];
    $fn[6] = (split qr{/}, $fn[6])[-1];
    FAF_wrap_stderr $fn[4];
    @fn[7,8] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[6];
    $fn[9] = FAF_unwrap_stderr $fn[4];
    ok !$fn[9], q|method is ready|;
    undef $fn[7];
    open $fn[5], q|<|, $fn[4];
    $fn[8] = $fn[5]->getline;
    chomp $fn[8];
    is $fn[8], qq|{{{$fn[2]}}}|, q|method is sent configured signal|;

    $fn[2] = $fn[3] eq q|TERM| ? q|PIPE| : q|TERM|;
    File::AptFetch::ConfigData->set_config(signal => $fn[2]);
    @fn[5,6] = tempfile q|void_destroy_XXXXXX|, DIR => $fn[0];
    FAF_prepare_method *{$fn[5]}, q|w-method|, $fn[4];
    close $fn[5];
    $fn[6] = (split qr{/}, $fn[6])[-1];
    FAF_wrap_stderr $fn[4];
    @fn[7,8] = FAF_safe_wrapper \&File::AptFetch::init, q||, $fn[6];
    $fn[9] = FAF_unwrap_stderr $fn[4];
    undef $fn[7];
    $fn[8] = t::TestSuite::FAF_fetch_stderr $fn[4];
    is $fn[8], qq|{{{$fn[2]}}}\n|, q|method is sent reconfigured signal|;

    File::AptFetch::ConfigData->set_config(config_source => $fn[9])
      unless $Apt_Lib;
    File::AptFetch::ConfigData->set_config(signal => $fn[3]);
    File::AptFetch::ConfigData->set_config(lib_method => $fn[1]);
    File::AptFetch::_uncache_configuration;
    FAF_clean_up $fn[0];
    rmdir $fn[0];
    undef @fn;         };

our @units = ( qw|
  handshake
  aptconfig configure
  destroy | );

t::TestSuite::FAF_do_units @ARGV;

# vim: syntax=perl
