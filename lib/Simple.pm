# $Id: Simple.pm 505 2014-06-12 20:42:49Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package File::AptFetch::Simple;
use version 0.77; our $VERSION = version->declare( v0.1.5 );
use base qw| File::AptFetch |;

use Carp;
use Cwd              qw| abs_path |;
use String::Truncate qw|    elide |;
use List::Util       qw| shuffle |;

=head1 NAME

File::AptFetch::Simple - convenience wrapper over File::AptFetch

=head1 SYNOPSIS

# TODO:

=head1 DESCRIPTION

When B<File::AptFetch> was started it was believed that it must be bare-bone
simple.
Then RL came (refer to I<v0.0.8> for details).
Besides B<F::AF> needed loads of handling on user's side of code.
Thus B<File::AptFetch::Simple> was born.

The sole purpose of B<F::AF::S> is to reach unimaginable simplicity to limits
of being usable in one-liner (and beyond).
To further convinience there's only one method what is also a constructor.
That combine has name L</B<request()>>.
Just like in parent class.
Only --
it won't B<return> unless all transfers are finished;
and it B<returns> object;
and it B<croak>s on errors.

Enjoy.

=head1 API

=over

=cut

=item B<request()>

Has two modes:  constructor and utility.
In either case a F::AF::S B<bless>ed object is returned.
Unless B<base> B<F::AF> object reported any problem,
then B<croak>s.
However, if that's a condition the parent doesn't care about
(as a matter of fact, B<F::AF> doesn't care that much about consistency of
messages and such)
but it looks terrible (and probably would lead to eventual timeout)
such conditions are B<carp>ed.

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

Unless explicitly noted:
any option used in C<cCM> sets defaults for this instance;
any option used in C<cUM> sets for this invocation.

=over

=item I<$options{beat}>

(optional, TRUE.)
That's the first progress reporting option --
this one is user-friendly.
L</_select_callback()> has detailed description.
B<(bug)>
Default should depend on I<STDERR> being visible in terminal.

=item I<$options{location}>

(optional, CWD.)
Sets dirname where acquired file will be placed.

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

B<(bug)>
Passively resists setting to value C<0>.

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

=item I<$options{wink}>

(optional, TRUE.)
That's the second progress reporting option --
this one is log-friendly.
Overwrites I<$options{beat}>'s output (if any).
Tries to be terminal saving too.
B<(bug)>
Should actually detect if there's any terminal on I<STDERR>.

Hints for filename and what APT method has said about it.
Not much.

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
B<(bug)>
As a matter of fact there's no way it can be anyhow affected.

=back

Diagnostics
(fatal conditions are specially marked)
(all errors that come from the parent are fatal by definition,
refer for B<F::AF> for details):

=over

=item {$options{method}} is required

B<(fatal)> B<(cCM)>
There's I<%options> HASH in I<@_>.
Unfortunately I<method> is FALSE.
No way to proceede with this.
B<(caveat)>
That hopes that there won't be a method named C<0>.
BTW parent will B<croak> on C<0> anyway.

=item either {$method} of {%options} is required

B<(fatal)> B<([cs]CM)>
During construction a method has to be initialized
what means it has to be picked up.
Invoking code must provide a method's name;
It didn't.
As a matter of fact I<@_> is totally empty.

=item first must be either {$method} of {%options}

B<(fatal)> B<([cs]CM)>
In this case I<@_> isn't empty,
but its leader is neither scalar ({$method}) nor HASH ({%options}).
Initialization code has no way to handle this.

=item got (%s) for (%s) without [request]

B<([cs]UM)>
Something wrong.
A message came in about I<$uri> (the latter C<%s>)
(it has I<$status> (the former C<%s>)).
It's surprise,
that I<$uri> was never requested.
B<(bug)>
Should dump the message.

=item got (%s) without {URI:}

B<([cs]UM)>
Something wrong.
A message just came in and it has no I<$uri>
(it has I<$status> (C<%s>)).
It's surprise,
I've never seen messages without that identification.
B<(bug)>
Should dump the damn message.

=back

=cut

my %stat = ( mark => time, trace => [ ] );
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
        $self->{wink} = !!$args->{wink}              if defined $args->{wink};
        $self->{beat} = !!$args->{beat}              if defined $args->{beat};
# FIXME:201405040354:whynot: Here F<0> has to be handled too.
        $self->{location} = $args->{location} || '.'              }
    else                                                  {
        $self = $class;
        if( $args && q|HASH| ne ref $args )  {
            unshift @subj, $args; $args = { } }
        elsif( !$args )                      {
            $args = { }                       }            }

# FIXME:201404012258:whynot: Must handle F<0> specially.
    my $loc = abs_path $args->{location} || $self->{location};
# TODO:201405020116:whynot: I<v5.12> is just behind the corner, you know.
# TODO:201405120124:whynot: Both should check for C<-t STDERR>.
    my $wink =
      defined $args->{wink} ? $args->{wink} :
      defined $self->{wink} ? $self->{wink} :
      File::AptFetch::ConfigData->config( q|wink| );
    my $beat =
      defined $args->{beat} ? $args->{beat} :
      defined $self->{beat} ? $self->{beat} :
      File::AptFetch::ConfigData->config( q|beat| );

# XXX:201405112010:whynot: That's just going to blow in your face.
    $self->{cheat_beat} = $beat ? "\r" : '';
    my $rv = $self->SUPER::request( map  {
        my $src = $_;
        $src =~ s{^file:}{copy:};
        my $bnam = ( split m{/} )[-1];
        qq|$loc/$bnam| => { uri => $src } } @subj );
    $rv                                                         and croak $rv;

    while( %{$self->{trace}} ) {
        $rv = $self->SUPER::gain;
        $rv                                                     and croak $rv;
        my $fn = $self->{message}{uri};
        unless( $fn                 )                                 {
# TODO:201403302300:whynot: Not in test-suite.
# TODO:201403302300:whynot: Additional diagnostics is missing.
            carp qq|got ($self->{status}) without {URI:}|;        next }
        elsif( !$self->{trace}{$fn} )                                 {
# TODO:201403221929:whynot: Not in test-suite.
            carp qq|got ($self->{status}) for ($fn) without [request]| }
        my $fnm = elide $fn, 25, { truncate => q|left| };
        if( grep $self->{Status} == $_, qw| 201 400 401 402 403 |) {
            delete $self->{trace}{$fn}                              }
# TODO:201406121825:whynot: Be more infomative, plz.
        print STDERR qq|$self->{cheat_beat}($fnm): ($self->{status})\n|      if
          $wink                 }
    delete $self->{cheat_beat};
       $self }

=item B<_read_callback()>

This does all required sampling for L</B<_select_callback()>>.
Routine for L<B<_read>|File::AptFetch/_read> is provided by
L<parent's callback|File::AptFetch/_read_callback>.

=cut

sub _read_callback {
    my $rec = shift;
    my $rv = File::AptFetch::_read_callback $rec;
    if( $rv )            {
        my $diff = defined $rec->{size} && defined $rec->{back} ?
                                    $rec->{size} - $rec->{back} : 0;
        $stat{inc} += $diff                                      if $diff > 0;
        $stat{activity}++ }
                $rv }

=item B<get_oscillator()>

Service routine for L</_select_callback()>.
It's public (in contrary with) because one day it will accept configuration
for oscillator.
Returns five bytes that somehow represent transfer went sleep.

=cut

my @void = qw| p e r l 5 |;
sub get_oscillator { join( '', @void = shuffle @void ) . q|X/s| }

=item B<_select_callback()>

This one does actual beat indicator,
unless forbidden (I<beat> of I<%opts> of L</B<request()>>).
Even if forbidden statistics is collected anyway.
Beat looks like this

    [19.55M/s] [17.72M/s  4.36M/s  3.48M/s]

B<(bug)>
Beats are output completely terminal blind --
no cleanups, no width checks;
simple leading C<\r>.
.

Beats are made with each I<$tick>.
In brackets are:

=over

=item *

Speed over last tick.

=item *

SMA of speed calculated over 5sec, 1min, and 5min.
As long as a subset haven't been accumulated they won't be shown
(however, due timer early initialization 5sec SMA will probably appear
instantly).
Subsets are package wide -- probably B<bug>
(problem is sampling is made in L</_read_callback> what doesn't know about
object).
Subsets are kept between invocations;
what gives, different transports obviously perform differently,
transfers over different paths obviously perform differently --
that doesn't mix well.
But being an eye candy, well, it could stay this way forever.

=back

B<(bug)>
Subset ranges should be configurable.

B<(bug)>
Final performance isn't left visible for further eye candy.

If transfer get stuck then speed is present with an oscillator --
you really don't want to know what it is, you gonna hate it.
B<(note)>
Now, when transfer speed goes to ground so does SMA
(that's what SMA is by design after all);
then, if transfer stalls long enough with probability ~50% SMA will hit
through C<0> and go negative
(rounding errors);
it was decided to present it with oscillator
(that one you already hate).
And when it stays positive it will be C<0.00b/s>.
(Those rounding errors are really small -- ~0.5e-8 small.)

Speeds are based on 1024.
Format is C<%5.2f>.
With prefixes only -- no unit;
unless there should not be any prefix -- then lone C<b> is used.
Supported prefixes are:
C<kilo>, C<mega>, C<giga>, C<tera>, C<peta>, C<exa>, C<zetta>, and C<yotta>
(or C<kibi>, C<mebi>, C<gibi>, C<tebi>, C<pebi>, C<exbi>, C<zibi>, and
C<yebi>, to make IEC happy)
(hard to imagine speeds like that).

B<(note)>
Due control-flow just after any C<200 URI Start> message
B<_select_callback()> is invoked before L</_read_callback()> what does
housekeeping.
Thus before L</_read_callback()> is invoked there's no sings transfer making
any progress.
That's presented with

    {{{ NOTHING HAPPENING!!! }}}

message what will stay for one I<$tick> and will be overwritten with, at
least,

    [ 0.00b/s] []

Maybe more.

=cut

my @marks = qw| b K M G T P E Z Y |;
my @indexes = ( 5, 60, 300 );

sub _select_callback                {
    my $faf = shift;
    my $sm = [ ];
    my $mark = time - $stat{mark} || 1;
    unless( exists $stat{inc} || $stat{activity} )       {
        $sm->[0] = undef                                  }
    elsif( !$stat{inc} && $stat{activity} )              {
        unshift @void, pop @void;
        push @$sm, get_oscillator                         }
    else                                                 {
        my $fix = 0;
# TODO:201406061509:whynot: Now that's gross;  go B<ceil()> asap, plz.
        $fix++                                   until 100 > sprintf q|%5.2f|,
          $stat{inc} / $mark / 2**($fix*10);
        push @$sm, sprintf q|%5.2f%s/s|,
          $stat{inc} / $mark / 2**($fix*10), $marks[$fix] }
    $stat{inc} ||= 0;
    my $bit = $stat{inc} / $mark;
    unshift @{$stat{trace}}, ( $bit ) x $mark;
    push @$sm, [ ];
    for( my $ix = 0; $ix < @indexes; $ix++ )             {
        if( @{$stat{trace}} < $indexes[$ix] )                    { next }
        unless( $stat{speeds}[$ix] )                                   {
            $stat{speeds}[$ix] += $_                                   foreach
              @{$stat{trace}}[0 ..  $indexes[$ix]-1];
            $stat{speeds}[$ix] /= $indexes[$ix]                         }
        else                                                           {
            $stat{speeds}[$ix] += $_/$indexes[$ix]                     foreach
              @{$stat{trace}}[0 ..  $mark-1],
              map -$_,
                @{$stat{trace}}[$indexes[$ix] .. $indexes[$ix]+$mark-1] }
# XXX:201406081721:whynot: And it really is.  Not mine, that's rounding error.
        if( $stat{speeds}[$ix] < 0 )               {
            push @{$sm->[-1]}, get_oscillator; next }
        my $fix = 0;
# TODO:201406081723:whynot: And here (B<ceil()>).
        $fix++                                                           until
          100 > sprintf q|%5.2f|, $stat{speeds}[$ix] / 2**($fix * 10);
        push @{$sm->[-1]}, sprintf q|%5.2f%s/s|,
          $stat{speeds}[$ix] / 2**($fix*10), $marks[$fix] }

    pop @{$stat{trace}}                   while @{$stat{trace}} > $indexes[2];

    if( $faf->{cheat_beat} )                   {
        $sm = !defined $sm->[0] ? q|{{{ NOTHING HAPPENING!!! }}}| :
          sprintf qq|[%s] [%s]|, $sm->[0], join ' ', @{$sm->[1]};
        print STDERR qq|$faf->{cheat_beat}$sm | }
    $stat{mark} = time;
    delete @stat{qw| inc activity |} }

File::AptFetch::set_callback
  read => \&_read_callback, select => \&_select_callback;

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
