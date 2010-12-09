#!/usr/bin/perl
# $Id: Build.PL 431 2010-12-05 01:07:42Z whynot $

use strict;
use warnings;

package main;
use version 0.50; our $VERSION = qv q|0.0.6|;

use Module::Build 0.20;

=head1 OVERVIEW

B<File::AptFetch> provides API for APT (Advanced Package Tool, that's the
Debian package management system) methods.
APT methods aren't libraries, they are executables
(placed, by default, in
F</var/lib/apt/methods>).
So it's not XS (and can't be), B<F::AF> forks.
However one doesn't need fork for each file or session.
The IPC is B<pipe>
(and can't be anything else
(later, I'll check if socket can be used instead of 2 pipes for each method)).
As you can see there's a limit of number of methods available simultaneously
posed by the maximum number of open filehandles
(APT methods aren't that numerous anyway).

The module is named B<File::AptFetch> because it always fetches.
I think that's possible to develop a method that would bring away files, but,
at present, there's none.
And I doubt there would be any.

Further reading:

=over

=item B<File::AptFetch>

POD of the module.
Covers API and provides examples of intended usage.
B<(bug)> It's underdeveloped yet.

=item B<File::AptFetch::Cookbook>

Provides some useful, I believe, findings on each method behaviour
and an overview, of my understanding, how that stuff works.
Look, APT methods API documentation is quite outdated.
Each method is undocumented completely.
B<(bug)> My knowledge of APT methods is very irregular, so is B<F::AF::C>.

=back

=head1 RUN-TIME REQUIREMENTS

=over

=item B<Perl>

B<v.5.8.0> or later.
Look, B<v.5.6.2> is C<woody>.
Eight years ago.
You must be kidding.

=item B<IO::Pipe>

Any version.
It's distributed with Perl itself.
In core since B<v.5.3.7>, predates debian, BTW.

=back

=head1 BUILD-TIME REQUIREMENTS

=over

=item B<Test::More>

Any version.
Should be distributed with Perl itself too.

=back

=cut

my $builder = Module::Build->new(
  module_name       =>                         q|File::AptFetch|,
  license           =>                                   q|lgpl|,
  dist_author       =>       q|Eric Pozharski <whynot@cpan.org>|,
  dist_version_from =>                   q|lib/File/AptFetch.pm|,
  sign              =>                                         1,
  requires          =>
  { perl        => qv( q|5.8.0| ),
    q|IO::Pipe| =>             ''                              },
  build_requires    => { q|Test::More| =>                   '' },
  PL_files          =>
 {( -f q|README.PL|  ? ( q|README.PL|  => q|README|  ) : ( )),
  ( -f q|Changes.PL| ? ( q|Changes.PL| => q|Changes| ) : ( )) },
  add_to_cleanup    =>
[qw| *.tmp *.bak foo.* FAF_*_?????? |,
  ( -f q|README.PL|  ? q|README|  : ( )),
  ( -f q|Changes.PL| ? q|Changes| : ( ))                      ]);

=head1 BUILD-TIME CONFIGURATION

=over

=cut

#$builder->config_data(lib_method    => q|/usr/lib/apt/methods|);

=item C<lib_method>

That sets location of APT methods.
It's unrequired,
it will be set any time APT configuration is sourced.
L<File::AptFetch/_cache_configuration> and
L<File::AptFetch/_uncache_configuration> have more.

=cut

$builder->config_data( config_source => [ qw| /usr/bin/apt-config dump | ]);

=item C<config_source>

Required.
C<ARRAY> ref that will be B<exec>ed.
L<File::AptFetch/_cache_configuration> has more.

=cut

$builder->config_data( signal => q|TERM| );

=item C<signal>

Required.
Names a signal that will be sent to method.
L<File::AptFetch/DESTROY> has more.

=cut

$builder->config_data( timeout => 120 );

=item C<timeout>

(I<v.0.0.8>)
Required.
I've believed, that could stay hardcoded.
I was wrong.
L<File::AptFetch/_read> has more.

=back

=cut

$builder->create_build_script( );

=head1 TEST-SUITE

Two things should be tested in regard with B<F::AF>:

=over

=item methods and structures

I wouldn't say I'm happy with this part (F<t/void.t>).
It's mostly a crash-type testing.
And a problem here is that I'm not completely sure what an input (from methods
side) here could be.

=item APT methods itself

Only local methods are tested.
And I<cdrom> method, among them, is no way touched.
Remote methods are missing from the test-suite.
This problem is easily fixable -- some kind Perlist could upload on CPAN some
modules, in B<Test> namespace, what would provide fake servers of
http://, ftp://, rsh:// etc protocols.
Anyone?

=back

And one note.
B<F::AF> is absolutely useles outside APT based world
(I'm not about F<*.deb>, I'm about APT).
Then F<t/file.t> and F<t/copy.t> skip completely.
Meanwhile F<t/void.t> enables some cute workaround, that would provide
all needed C<apt-config(1)> functionality without that executable itself.
(Just in case on that platform there will be Debian some day.)
But we still stay within POSIX world -- no future outside.

=head1 AVAILABILITY

=over

=item pure distribution

L<http://search.cpan.org/dist/File-AptFetch/>

=item and debianization stuff too

# TODO

=item subversion (root)

# TODO

=back

=head1 BUGS

=over

=item please report here

L<http://rt.cpan.org/Public/Dist/Display.html?Name=File-AptFetch/>

=item please don't report there

# TODO

=back

=head1 COPYRIGHT AND LICENSING

=over

=item *

Copyright 2009 by Eric Pozharski E<lt>whynot@cpan.orgZ<>E<gt>

=item *

AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

=item *

GNU Lesser General Public License v3
L<http://www.gnu.org/licenses/lgpl.txt>

=back
