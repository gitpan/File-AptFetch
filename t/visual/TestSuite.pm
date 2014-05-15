# $Id: TestSuite.pm 501 2014-05-14 22:19:48Z whynot $
# Copyright 2014 Eric Pozharski <whynot@pozharski.name>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package t::visual::TestSuite;
use version 0.77; our $VERSION = version->declare( v0.1.1 );

use base qw| Exporter |;
use Getopt::Long;

=head1 NAME

t::visual::TestSuite - place to refactor into from F<t/visual>

=head1 DESCRIPTION

That's a place for refactored parts (none so far) of scripts in F<t/visual>.

=head1 OPTION HANDLING

Provides two option hashes I<--global> and I<--local>.
A script that B<use>s B<t::v::TS> is supposed to understand (verify and use)
those hashes itself.
Supposedly, I<--glboal> is for I<cCM> and I<--local> is for I<cUM> of
B<F::AF::S::request()>.
A script must provide I<%main::opts> where options will be stored.

=cut

GetOptions \%main::opts, qw{ global|g=s% local|l=s% help version }      or die
  q|[GetOptions] failed\n|;
$main::opts{help}                    and die qq|[--help] isn't implemented\n|;
$main::opts{version}                and die qq|[--version] isn't implemented|;

=head1 OVERRIDES

Those are provided to make routines of B<t::TS> available without getting in
fight with B<Test::More>.
Otherwise, routines of B<t::TS> should be duplicated here.

=over

=cut

package Test::More;

=item B<diag()>

Overrides B<Test::More::diag()>.
For B<FAFTS_wrap()> and B<FAFTS_discover_config()>

=cut

sub diag ( @ ) { }

=back

=cut

1

