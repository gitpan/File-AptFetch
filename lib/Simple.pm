# $Id: Simple.pm 496 2014-02-26 17:39:18Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package File::AptFetch::Simple;
use version 0.77; our $VERSION = version->declare( v0.1.1 );
use base qw| File::AptFetch |;

use Carp;
use Cwd qw| abs_path |;

=head1 NAME

File::AptFetch::Simple - simplifing wrapper above F::AF

=head1 SYNOPSIS

# TODO:

=head1 DESCRIPTION

# TODO:

=head1 API

=over

=item B<request()>

Has two modes:  constructor and utility.
In either case a F::AF::S B<bless>ed object is returned.
Unless B<base> B<F::AF> object reported any problem,
then B<croak>s.

=over

=item Constructor Mode

    # complete CM -- cCM
    $fafs = File::AptFetch::Simple->request( { %options }, @uris );
    # simplified CM -- sCM
    $fafs = File::AptFetch::Simple->request( $method, @uris );

I<%options> are some parameters what will be somehow processed upon
construction and mostly saved for later use.
However, if defaults are ok then only one required parameter
(that is I<$options{method}>) can be passed as first scalar.
Known keys (and I<$method>) are described a bit later.

I<@uris> is a list of scalars.
If empty, then constructor just blows through construction and returns
(it doesn't mean it's in vein, the requested method is initialized).
In detail description of I<%options> a bit later.

=item Utility Mode

    # complete UM -- cUM
    $fafs->request( { %options }, @uris );
    # simplified UM -- sUM
    $fafs->request( @uris );

If first argument isn't a HASH,
then B<reqeust()> believes that I<%options> is omitted.
However, there's a quirk.
Due implementation idiosyncrasy,
if first argument is FALSE it's ignored completely.
Consider those are reserved (even if they are not).
Are we cool now?

If I<@uris> is empty then silently succeedes.
In detail description of I<@uris> a bit later.

=item I<%options>

=over

=item I<$options{location}>

Optional.
Defaults to CWD.
Sets dirname where acquired file will be placed.
Set in cUM leaves set in cCM (if any) intact.

B<(caveat)>
When applied I<$options{location}> will be expanded to be absolute
(as required by APT method API).
However, that expansion is performed with each B<request()>
and, as mentioned above, transparently.
Thus if *you* set I<$options{location}> to non-absolute dirname,
than B<request()> once,
then *your* script changes CWD,
then B<request()> again,
then those B<request()>s will put results in two different dirctories.

B<(bug)>
Neither checks nor makes sure I<$options{location}> is anyway usable.

=item I<$options{method}>

=item I<$method>

In C<[cs]CM> required, otherwise silently ignored.
If there's no such F<method> installed B<croak>s immeidately.
C<file> is silengtly replaced with C<copy>;
C<copy> is passed through.

B<(note)>
You should understand.
B<F::AF::S> is a B<convenience> wrapper about B<F::AF>.
Second, B<F::AF> interfaces with APT methods what are all Debian.
It's reasonable to foresee that URIs will be constructed from those found in
F</etc/apt/sources.list>
(and, probably, nothing else).
But there's no URI of C<copy:> type,
you should do that substitution yourself.
Else B<F::AF::S> could do it for you.

=back

=item I<@uris>

Requirements for I<%source> described in L<B<F::AF>|File::AptFetch/request()>
still apply.
Shortly:
full pathnames,
no schema,
one (local mehtods) or two (remote methods) leading slashes.
B<(bug)>
That's not convinient in any reasonable way.

I<$target> (of underlying B<request()> of B<F::AF>) isn't required.
It's constructed from requested URI:
current value of I<$options{location}> will be concatenated with a basename of
currently processed I<$uris[]>.
The separator is slash.
(What else, it's *nix, for kernel's sake.)
(B<(bug)>
As a matter of fact there's no way it can be anyhow affected.

=back

=cut

sub request {
    my( $class, $args, @subj ) = @_;
    my $self;
    if( $class->isa( q|File::AptFetch| ) && !ref $class ) {
        defined $args  or croak q|either {$method} or {%options} is required|;
        !ref $args || q|HASH| eq ref $args                            or croak
          q|first must be either {$method} or {%options}|;
        $args = { method => $args }               unless q|HASH| eq ref $args;
        defined $args->{method}    or croak q|{$options{method}} is required|;
        my $method = $args->{method} eq q|file| ? q|copy| : $args->{method};
        $self = File::AptFetch->init( $method );
        ref $self                                              or croak $self;
        bless $self, $class;
        $self->{location} = $args->{location}              }
    else                                                  {
        $self = $class;
        if( $args && q|HASH| ne ref $args )  {
            unshift @subj, $args; $args = { } }
        elsif( !$args )                      {
            $args = { }                       }            }
    my $loc = abs_path $args->{location} || $self->{location} || '.';
    my $rv = $self->SUPER::request( map  {
        my $src = $_;
        $src =~ s{^file:}{copy:};
        my $bnam = ( split m{/} )[-1];
        qq|$loc/$bnam| => { uri => $src } } @subj );
    $rv                                                         and croak $rv;
    $self->{mark} += @subj;
    while( $self->{mark} )         {
        my $rv = $self->SUPER::gain;
        $rv                                                     and croak $rv;
        $self->{mark}--                         if grep $self->{Status} == $_,
          qw| 201 400 401 402 403 | }
       $self }

=back

=head1 SEE ALSO

L<File::AptFetch>

=head1 AUTHOR

Eric Pozharski, <whynot@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2014 by Eric Pozharski

This library is free in sense: AS-IS, NO-WARANRTY, HOPE-TO-BE-USEFUL.
This library is released under GNU LGPLv3.

=cut

1
