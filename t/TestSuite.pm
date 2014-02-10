# $Id: TestSuite.pm 491 2014-01-31 22:59:49Z whynot $
# Copyright 2009, 2010, 2014 Eric Pozharski <whynot@pozharski.name>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package DB;
sub get_fork_TTY { xterm_get_fork_TTY() }

package t::TestSuite;
use version 0.50; our $VERSION = qv q|0.1.2|;
use parent qw| Exporter |;
use lib     q|./blib/lib|;

use Carp;
use Module::Build;
use Cwd;
use File::Temp qw| tempfile tempdir |;

our @EXPORT_OK =
qw| FAFTS_diag                       FAFTS_show_message
    FAFTS_tempfile                        FAFTS_tempdir
    FAFTS_prepare_method FAFTS_wrap FAFTS_wait_and_gain
                                         FAFTS_get_file |;
our %EXPORT_TAGS =
( diag => [qw| FAFTS_diag                       FAFTS_show_message |],
  temp => [qw| FAFTS_tempfile                        FAFTS_tempdir |],
  mthd => [qw| FAFTS_prepare_method FAFTS_wrap FAFTS_wait_and_gain |],
  file => [qw|                                      FAFTS_get_file |] );
our $Empty_MD5 = q|d41d8cd98f00b204e9800998ecf8427e|;

$ENV{PERL5LIB} = getcwd . q(/blib/lib);

# FIXME: B<&Module::Build::runtime_params> apeared in v0.28
our $Verbose = eval { Module::Build->current->runtime_params(q|verbose|); };

=head1 DIAGNOSTIC OUTPUT

=over

=cut

=item B<FAFTS_diag()>

    use t::TestSuite qw/ :diag /;
    FAFTS_diag $@

Outputs through B<Test::More::diag()>.
Void if I<STDOUT> isa not terminal, I<$ENV{QUIET}> is TRUE, I<@_> is empty, or
I<@_> consists of FALSEs.

=cut

sub FAFTS_diag ( @ )      {
    -t STDOUT && !$ENV{QUIET} && @_ && grep $_, @_                  or return;
    Test::More::diag( @_ ) }

=item B<FAFTS_show_message>

    use t::TestSuite qw/ :diag /;
    FAFTS_show_message %arg

B<diag>s (debian config alike) contents of a I<%arg>.
That I<%arg> is supposedly parsed I<$message> from a method.
Void if I<STDOUT> isa not terminal, I<$ENV{QUIET}> isa TRUE, or I<@_> is
empty.

=back

=cut

sub FAFTS_show_message (%)                                               {
    -t STDOUT && !$ENV{QUIET} && @_                                 or return;
    my %message = @_;
    Test::More::diag(
      map sprintf( qq|%s: %s\n|, $_, $message{$_} ), sort keys %message ) }

=head1 FILES AND DIRECTORIES

=over

=cut

=item B<FAFTS_tempfile()>

    use t::TestSuite qw/ :temp /;
    $tempfile = FAFTS_tempfile %args;

Creates a temporal file.
This file is scheduled for deletion when test-unit completes.
The file is named:
F<skip_$caller_$nick_XXXX>
Known parameters are:

=over

=item I<$caller>

If unset, reasonable default based on B<caller> return is provided.

=item I<$content>

If set will be fed into just created file.

=item I<$dir>

Requests file to be created in specific directory.
B<cwd()> isa default.

=item I<$nick>

Arbitrary identification what has meaning in calling code.
C<void> isa deafult.

=item I<$suffix>

Obvious.

=back

Returns a filename.
Due to I<$args{dir}> defaulting filename is always fully qualified;
probably canonicalized.
A filehandle is implicitly closed.

=cut

my @Tempfiles = ( $$ );
sub FAFTS_tempfile ( % ) {
    my %args = @_;
    my $fn =
      sprintf q|skip_%s_%s_XXXX|,
        $args{caller} || ( split m{/}, ( caller )[1])[-1],
        $args{nick} || q|void|;
    my $fh;
    ( $fh, $fn ) = tempfile $fn,
      DIR => $args{dir} || cwd, SUFFIX => $args{suffix} || '';
    push @Tempfiles, $fn;
    print $fh $args{content}                                if $args{content};
    return $fn            }

END { unlink @Tempfiles if $$ == shift @Tempfiles }

=item B<FAFTS_tempdir()>

    use t::TestSuite qw/ :temp /;
    $tempdir = FAFTS_tempdir %args;

Creates a temporal directory.
This directory is scheduled for deletion when test-unit completes.
The directory is named:
F<skip_$caller_$nick_XXXX>.
Known parameters are:

=over

=item I<$caller>

If unset, reasonable default based on B<caller> return is provided.

=item I<$dir>

Overrides default provided by B<File::Temp::tempdir()>.

=item I<$nick>

Arbitrary identification what has meaning in callig code.
C<void> isa default.

=item I<$suffix>

Obvious.

=back

Returns dirname.
If I<$args{dir}> is set, then dirname is expanded to be fully qualified;
no canonicalization.

=cut

sub FAFTS_tempdir ( % ) {
    my %args = @_;
    my $dn = sprintf q|skip_%s_%s_XXXX|,
      $args{caller} || ( split m{/}, ( caller )[1])[-1],
      $args{nick} || q|void|;
    $dn = tempdir $dn,
      DIR => $args{dir}, SUFFIX => $args{suffix}, CLEANUP => 1;
    $dn = sprintf q|%s/%s|, cwd, $dn                        unless $args{dir};
    return $dn           }

sub FAFTS_wrap ( & )                         {
    my $code = shift;
    my $stderr = FAFTS_tempfile nick => q|stderr|;
    open my $bckerr, q|>&|, \*STDERR     or croak qq|save [dup] (STDERR): $!|;

    open STDERR, q|>|, $stderr;
    my $rv = $code->();
    open STDERR, q|>&|, $bckerr       or croak qq|restore [dup] (STDERR): $!|;

    FAFTS_diag ref $rv eq q|File::AptFetch| ?
                   qq|method: ($rv->{pid})| : qq|RV: ($rv)|;
    open $bckerr, q|<|, $stderr             or croak qq|[open] ($stderr): $!|;
    read $bckerr, $stderr, -s $bckerr;
    FAFTS_diag $stderr;
    return wantarray ? ( $rv, $stderr ) : $rv }

sub FAFTS_get_file ( $ ) {
    my $fn = shift @_;
    open my $fho, q|<|, $fn                  or croak qq|[open]{r} ($fn): $!|;
    read $fho, my $buf, -s $fho;
    FAFTS_diag $buf;
    open $fho, q|>|, $fn                     or croak qq|[open]{w} ($fn): $!|;
                     $buf }

sub FAFTS_prepare_method ( $$$@ ) {
    my($fh, $method, $stderr, @cmds) = ( @_ );
    $stderr ||= q|/dev/null|;
    open my $fho, q|>|, $fh                   or croak qq|[open] ($_[0]): $!|;
    open my $fhi, q|<|, qq|t/$method|;
    read $fhi, my $buf, -s $fhi;
    print $fho $buf;
    print $fho "\n";
    print $fho qq|__DATA__\n|;
    print $fho qq|$stderr\n|;
    print $fho qq|$_\n|                                         foreach @cmds;
    chmod 0755, $fho or croak qq|[chmod] ($fh): $!|;
           ( split m{/}, $fh )[-1] }

sub FAFTS_wait_and_gain ( $;$ )              {
    my $eng = shift @_;
    my $timeout = shift @_ || 10;
    my( $rc, $stderr );
    my $mark = $eng->{message};
    while( $timeout-- ) {
        my $serr;
        ( $rc, $serr ) = FAFTS_wrap { $eng->gain };
        $stderr .= $serr;
        (!$mark && $eng->{message}) ||
          $mark != $eng->{message}  ||
          $rc                                                        and last;
        sleep 1          }
    FAFTS_diag $rc                                                 unless $rc;
    return wantarray ? ( $rc, $stderr ) : $rc }

=item B<FAFTS_discover_lib()>

    $lib = t::TestSuite::FAFTS_discover_lib;
    defined $lib or die "not a *nix";
    $lib eq '' or die "not a debian";

Utility routine.
Discovers a place where methods are located.
Returns:

=over

=item *

Value of I<$lib_method> of B<File::AptFetch::ConfigData>, if preset.

=item *

C<undef>, if not a *nix, or I<@$config_source> of B<F::AF::CD> isn't set or
isn't ARRAY.

=item *

Empty line, if I<$config_source[0]> of B<F::AF::CD> isn't executable or
pipe-open failed, or wanabe I<$lib_method> stays FALSE.

=item *

whatever value of I<Dir::Bin::methods> parameter has been found.

=back

=cut

sub FAFTS_discover_lib ( ) {
    -e q|/dev/null| && -r _ && -w _                           or return undef;
    my $lib = File::AptFetch::ConfigData->config( q|lib_method| );
    $lib                                                      and return $lib;
    my $aptconfig = File::AptFetch::ConfigData->config( q|config_source| );
    $aptconfig && ref $aptconfig eq q|ARRAY|                  or return undef;
    -x $aptconfig->[0]                                           or return '';
    my $pid = open my $fh, q{-|}, @$aptconfig                    or return '';
    while(my $line = <$fh>) {
        $line =~ m{^Dir::Bin::methods\s+"(.+)";$}                     or next;
        $lib = $1;      last }
    undef                                                      while( <$fh> );
    close $fh                  or die qq|[apt-config]: close failed: $! ($?)|;
    waitpid $pid, 0;
# XXX:20090509002544:whynot: What if I<$lib> is C<0>?
                 $lib || '' }

1;
