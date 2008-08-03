package WWW::CPANRatings::RSS;

use warnings;
use strict;

our $VERSION = '0.0101';


use XML::Simple;
use LWP::UserAgent;

use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw/
    error
    ua
    ratings
/;

sub new {
    my $class = shift;
    my %args = @_;
    $args{ua}{timeout} ||= 30;

    my $self = bless {}, $class;

    $self->ua( LWP::UserAgent->new( %{ $args{ua} || {} } ) );

    return $self;
}

sub fetch {
    my $self = shift;

    $self->$_(undef)
        for qw/error ratings/;

    my $response = $self->ua->get('http://cpanratings.perl.org/index.rss');
    unless ( $response->is_success ) {
        $self->error( 'Network error: ' . $response->status_line );
        return; 
    }

    my $feed = XMLin( $response->content );
    my @ratings;
    for my $item ( @{ $feed->{item} || [] } ) {
        my ( $rating, $comment ) = $item->{description}
        =~ /Rating: \s* ([\d.]+) \s* stars \s* (.+)/sx;

        $rating = 'N/A'
            unless defined $rating;

        $comment = $item->{description}
            unless defined $comment;

        push @ratings, {
            creator     => $item->{'dc:creator'},
            link        => $item->{link},
            dist        => $item->{title},
            comment     => $comment,
            rating      => $rating,
        };
    }

    return $self->ratings( \@ratings );
}


1;
__END__

=head1 NAME

WWW::CPANRatings::RSS - get information from RSS feed on http://cpanratings.perl.org/

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::CPANRatings::RSS;

    my $rate = WWW::CPANRatings::RSS->new;

    $rate->fetch
        or die $rate->error;

    for ( @{ $rate->ratings } ) {
        printf "%s - %s stars - by %s\n--- %s ---\nsee %s\n\n\n",
            @$_{ qw/dist rating creator comment link/ };
    }


    WWW-Google-Video - 2 stars - by Zoffix Znet
    --- The module doesn't do any error checking when using get() from LWP::Simple which causes warnings to be printed due to subsequent regex matches done on ... ---
    see http://cpanratings.perl.org/#4478

    String-String - 1 stars - by BKB
    --- A completely pointless module, it consists of exactly one line of code, and a hundred lines of documentation. I don't know why anyone would need to do ... ---
    see http://cpanratings.perl.org/#4476

    # ... and so on...

=head1 DESCRIPTION

The module provides access to information provided by RSS feed on
L<http://cpanratings.perl.org/>, which is basically several of most
recent reviews.

=head1 CONSTRUCTOR

=head2 C<new>

    my $rate = WWW::CPANRatings::RSS->new;

    my $rate = WWW::CPANRatings::RSS->new(
        ua => {
            agent   => 'Foo',
            timeout => 30,
        },
    );

Returns a freshly baked C<WWW::CPANRatings::RSS> object. Arguments are
passed in a key/value fashion. So far there is only one argument C<ua>.

=head3 C<ua>

    ->new(
        ua => {
            agent   => 'Foo',
            timeout => 30,
        },
    );

B<Optional>. Takes a hashref as a value. This hashref will be directly
dereferenced into L<LWP::UserAgent> object used by this module. For
possible arguments see L<LWP::UserAgent> documentation. B<Defaults to:>
C<< { timeout => 30 } >>

=head1 METHODS

=head2 C<fetch>

    my $ratings = $rate->fetch
        or die $rate->error;

Takes no arguments. Instructs the object to fetch the RSS feed on
L<http://cpanratings.perl.org/>.
On success returns an I<arrayref> of hashrefs,
which are described below. On failure returns either C<undef> or an
empty list, depending on the context, in which case the C<error()> method
will return the explanation of the error. The elements (hashrefs) in the
returned arrayref represent cpanratings reviews, in reverse-chronological
order (i.e. newest first). The format of each hashref is as follows:

    $VAR1 = {
          'link' => 'http://cpanratings.perl.org/#4446',
          'comment' => 'This module has failed on all swf\'s ive tried it on.  All attempts at transcoding has resulted in contentless flv that will not play.
',
          'creator' => 'Dave Williams',
          'dist' => 'FLV-Info',
          'rating' => '1'
    };

=head3 C<link>

    { 'link' => 'http://cpanratings.perl.org/#4446', }

The C<link> key will contain a string which represents a link to the review.

=head3 C<comment>

    { 'comment' => 'This module has failed on all swf\'s ive tried it on.  All attempts at transcoding has resulted in contentless flv that will not play. }

The C<comment> key will contain a string representing the (often partial,
starting from the beginning) content of the review.

=head3 C<creator>

    { 'creator' => 'Dave Williams', }

The C<creator> key will contain a string which represents the name of
the person who created the review.

=head3 C<dist>

    { 'dist' => 'FLV-Info', }

The C<dist> key will contain a string which is the name of the distribution
that was reviewed.

=head3 C<rating>

    { 'rating' => '1' }

    { 'rating' => 'N/A' }

The C<rating> key will contain the rating of the distribution
given by the creator of the review. It will either be the number of "stars"
or 'N/A' if no rating was given.

=head2 C<error>

    my $ratings = $rate->fetch
        or die $rate->error;

In case of an error during the call to C<fetch()> method, the C<error>
method will return a string which describes the reason for failure.

=head2 C<ratings>

    $rate->fetch
        or die $rate->error;

    my $ratings = $rate->ratings;

Must be called after a successful call to C<fetch()> method. Returns
the exact same arrayref as the last call to C<fetch()> returned;

=head2 C<ua>

    my $ua_obj = $rate->ua;

    $rate->ua( LWP::UserAgent->new );

Returns an L<LWP::UserAgent> object used internally for fetching the
RSS feed. When called with an optional argument, which must be an
L<LWP::UserAgent> or a compatible object, will use the provided object
in any subsequent calls to C<fetch()> method.

=head1 PREREQUISITES

For healthy operation this module needs L<XML::Simple> and L<LWP::UserAgent>

=head1 EXAMPLES

The C<examples/> directory of this distributing contains a script
presented in the SYNOPSYS section.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-cpanratings-rss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-CPANRatings-RSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::CPANRatings::RSS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-CPANRatings-RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-CPANRatings-RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-CPANRatings-RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-CPANRatings-RSS>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

