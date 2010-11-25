# $Id: TestSuite.pm 354 2009-05-09 22:15:56Z whynot $

package t::TestSuite;

use strict;
use warnings;
use version 0.50;

use base       qw| Exporter |;
use Cwd;
use Data::Dumper;
use Module::Build;
use File::Temp qw| tempfile |;

our $VERSION = qv q|0.0.10|;
our @EXPORT_OK = qw|
  FAF_wrap_stderr FAF_unwrap_stderr FAF_fetch_stderr
  FAF_safe_wrapper FAF_wait_and_gain
  FAF_prepare_method
  FAF_diag FAF_show_message FAF_clean_up |;
our $Empty_MD5 = q|d41d8cd98f00b204e9800998ecf8427e|;

use lib q|./blib/lib|;

$ENV{PERL5LIB} = getcwd . q(/blib/lib);

# FIXME: B<&Module::Build::runtime_params> apeared in v0.28
our $Verbose = eval { Module::Build->current->runtime_params(q|verbose|); };

my $Wrap_Stderr;

sub FAF_diag (@)         {
    return unless $Verbose && @_;
    Test::More::diag(@_); };

sub FAF_show_message (\%)   {
    return unless $Verbose && keys %{$_[0]};
    my %message = %{shift @_};
    Test::More::diag(
      map
        sprintf(qq|I<%s> C<%s>\n|, $_, $message{$_}),
        sort keys %message); };

sub FAF_wrap_stderr (\[*$]) {
    my $fh;
    if(ref ${$_[0]} eq q|GLOB|)     {
        $fh = ${shift @_};           }
    else                            {
        open $fh, q|>|, ${shift @_}; };
    open $Wrap_Stderr, q|>&|, \*STDERR;
    open STDERR, q|>&|, $fh;
    return $fh;              };

sub FAF_fetch_stderr (\[*$]) {
    my $wrap;
    if(ref ${$_[0]} eq q|GLOB|)       {
        $wrap = ${shift @_};           }
    else                              {
        open $wrap, q|<|, ${shift @_}; };
    do                  {
        local $/;
        $wrap = <$wrap>; };
    FAF_diag $wrap
      unless $wrap;
    return $wrap;             };

sub FAF_unwrap_stderr (;\[*$]) {
    open STDERR, q|>&|, $Wrap_Stderr;
    undef $Wrap_Stderr;
    $_[0] or return;
# XXX: He-he...  I've commited sin...
    return &FAF_fetch_stderr;   };

sub FAF_safe_wrapper (&$@) {
    my($method, $object) = ( shift @_, shift @_ );
    $object ||= q|File::AptFetch|;
    my $rc = $method->($object, @_);
    FAF_diag qq|method: [$rc->{pid}]|
      if ref $rc eq $object;
    return $rc;             };

sub FAF_clean_up ($) {
    my $rc;
    my $dir = shift @_;
    opendir my($dh), $dir;
    while(my $file = readdir $dh)       {
        -d qq|$dir/$file|     and next;
        unlink qq|$dir/$file| and $rc++; };
    return $rc;       };

sub FAF_do_units (@)                                            {
    my @set = @_ ? @_ : @main::units;
    $main::units{$_}->()
      foreach @set;
    my @fails;
    while(-1 != (my $pid = wait)) {
        push @fails, $pid;         };
    FAF_diag join ' ', map qq|[$_]|, @fails
      if @fails;
    Test::More::ok(!@fails, scalar(@fails) . q| zombies found|); };

sub FAF_prepare_method (\*$$@) {
    my($fho, $method, $stderr, @cmds) = ( @_ );
    $stderr ||= q|/dev/null|;
    open my $fhi, q|<|, qq|t/$method|;
    do                        {
        local $/;
        print $fho ( <$fhi> ); };
    print $fho "\n";
    print $fho qq|__DATA__\n|;
    print $fho qq|$stderr\n|;
    print $fho qq|$_\n|
      foreach @cmds;
    chmod 0755, $fho;           };

sub FAF_wait_and_gain ($;$) {
    my $eng = shift @_;
    my $timeout = shift @_ || 10;
    my $rc;
    my $mark = $eng->{message};
    while($timeout--) {
        $rc = FAF_safe_wrapper \&File::AptFetch::gain, $eng;
        (!$mark && $eng->{message}) ||
          $mark != $eng->{message}  ||
          $rc                       and last;
        sleep 1;       };
    FAF_diag $rc
      unless $rc;
    return $rc;              };

sub FAF_discover_lib () {
    return undef
      unless -e q|/dev/null| && -r _ && -w _;
    my $lib = File::AptFetch::ConfigData->config(q|lib_method|);
    return $lib
      if $lib;
    my $aptconfig = File::AptFetch::ConfigData->config(q|config_source|);
    return undef
      unless $aptconfig && ref $aptconfig eq q|ARRAY|;
    return ''
      unless -x $aptconfig->[0];
    my $pid = open my $fh, q{-|}, @$aptconfig;
    return ''
      unless $pid;
    while(my $line = <$fh>) {
        $line =~ m{^Dir::Bin::methods\s+"(.+)";$} or
          next;
        $lib = $1;
        last;                };
    undef
      while(<$fh>);
    close $fh or
      die qq|(apt-config): close failed: $! ($?)|;
    waitpid $pid, 0;
# XXX:20090509002544:whynot: What if I<$lib> is C<0>?
    return $lib || '';   };

if($INC{q|perl5db.pl|}) {
    require t::DB;
    $Verbose = 0;        };

1;
