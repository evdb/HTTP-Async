use strict;
use warnings;

# Provide a simple server that can be used to test the various bits.
package TestServer;
use base qw/Test::HTTP::Server::Simple HTTP::Server::Simple::CGI/;

use Time::HiRes qw(sleep time);
use Data::Dumper;
use LWP::UserAgent;

sub new {
    my ($class, $port) = @_;
    
    $port ||= 10_249; # randomish port
    
    return $class->SUPER::new($port);
}

sub handle_request {
    my ( $self, $cgi ) = @_;
    my $params = $cgi->Vars;

    # If we are on port 8081 then we are a proxy - we should forward the
    # requests.
    return act_as_proxy(@_) if $self->{is_proxy};

    # We should act as a final destination server and so expect an absolute URL.
    my $request_uri = $ENV{REQUEST_URI};
    if ( $request_uri !~ m!^/! ) {
        warn "ERROR - not absolute request_uri '$request_uri'";
        return;
    }

    # Flush the output so that it goes straight away. Needed for the timeout
    # trickle tests.
    $self->stdout_handle->autoflush(1);

     # warn "START REQUEST - " . time;
     # warn Dumper($params);

    # Do the right thing depending on what is asked of us.
    if ( exists $params->{redirect} ) {
        my $num = $params->{redirect} || 0;
        $num--;

        if ( $num > 0 ) {
            print $cgi->redirect( -uri => "?redirect=$num", -nph => 1, );
            print "You are being redirected...";
        }
        else {
            print $cgi->header( -nph => 1 );
            print "No longer redirecting";
        }
    }

    elsif ( exists $params->{delay} ) {
        sleep( $params->{delay} );
        print $cgi->header( -nph => 1 );
        print "Delayed for '$params->{delay}'.\n";
    }

    elsif ( exists $params->{trickle} ) {

        print $cgi->header( -nph => 1 );

        my $trickle_for = $params->{trickle};
        my $finish_at   = time + $trickle_for;

        local $| = 1;

        while ( time <= $finish_at ) {
            print time . " trickle $$\n";
            sleep 0.1;
        }

        print "Trickled for '$trickle_for'.\n";
    }

    elsif ( exists $params->{bad_header} ) {
        my $headers = $cgi->header( -nph => 1, );

        # trim trailing whitspace to single newline.
        $headers =~ s{ \s* \z }{\n}xms;

        # Add a bad header:
        $headers .= "Bad header: BANG!\n";

        print $headers . "\n\n";
        print "Produced some bad headers.";
    }

    elsif ( my $when = $params->{break_connection} ) {

        for (1) {
            last if $when eq 'before_headers';
            print $cgi->header( -nph => 1 );

            last if $when eq 'before_content';
            print "content\n";
        }
    }

    elsif ( my $id = $params->{set_time} ) {
        my $now = time;
        print $cgi->header( -nph => 1 );
        print "$id\n$now\n";
    }

    elsif ( exists $params->{not_modified} ) {
        my $last_modified = HTTP::Date::time2str( time - 60 * 60 * 24 );
        print $cgi->header(
            -status         => '304',
            -nph            => 1,
            'Last-Modified' => $last_modified,
        );
        print "content\n";
    }

    else {
        warn "DON'T KNOW WHAT TO DO: " . Dumper $params;
    }

    # warn "STOP REQUEST  - " . time;

}

sub act_as_proxy {
    my ( $self, $cgi ) = @_;

    my $request_uri = $ENV{REQUEST_URI};

    # According to the RFC the request_uri must be fully qualified if the
    # request is to a proxy and absolute if it is to a destination server. CHeck
    # that this is the case.
    #
    #   http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5.1.2
    if ( $request_uri !~ m!^https?://! ) {
        warn "ERROR - not fully qualified request_uri '$request_uri'";
        return;
    }

    my $response = LWP::UserAgent->new( max_redirect => 0 )->get($request_uri);

    # Add a header so that we know that this was proxied.
    $response->header( WasProxied => 'yes' );

    print $response->as_string;
    return 1;
}

1;
