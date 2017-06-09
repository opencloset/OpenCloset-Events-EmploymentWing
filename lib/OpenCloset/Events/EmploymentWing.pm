package OpenCloset::Events::EmploymentWing;

use utf8;
require Exporter;
@ISA    = qw/Exporter/;
@EXPORT = qw/$EW_STATUS_BOOKING $EW_STATUS_COMPLETE $EW_STATUS_RETURNED $EW_STATUS_CANCEL/;

use strict;
use warnings;

use HTTP::CookieJar;
use HTTP::Tiny;
use Path::Tiny;

=encoding utf8

=head1 NAME

OpenCloset::Events::EmploymentWing - 취업날개 API(?) client

=head1 SYNOPSIS

    use OpenCloset::Events::EmploymentWing;
    my $client  = OpenCloset::Events::EmploymentWing->new( username => 'xxxx', password => 'xxxx' );
    my $success = $client->update_status($rent_num, $EW_STATUS_COMPLETE);

=cut

our $HOST = "http://dressfree.net";

=head1 METHODS

=head2 new( username => $username, password => $password )

    my $client = OpenCloset::Events::EmploymentWing->new(username => $username, password => $password);
    die "login failed" unless $client;

=cut

sub new {
    my ( $class, %args ) = @_;
    return unless $args{username};
    return unless $args{password};

    my $self = {
        username => $args{username},
        password => $args{password},
        cookie   => $args{cookie} || "$ENV{HOME}/.opencloset.cookie.txt",
    };

    my $cookie    = path( $self->{cookie} )->touch;
    my $cookiejar = HTTP::CookieJar->new->load_cookies( $cookie->lines );
    $self->{http} = HTTP::Tiny->new(
        timeout         => 5,
        cookie_jar      => $cookiejar,
        default_headers => { agent => __PACKAGE__ }
    );

    my ($cookies) = $cookiejar->cookies_for($HOST);

    ## `expires` 가 없음
    ## 임의로 +10m 으로 설정
    my $access_time = $cookies->{last_access_time};
    if ( !$access_time || $access_time + 600 < time ) {
        my $res = $self->{http}->post_form(
            "$HOST/dev/login_ok.php",
            {
                cu_page => "$HOST/service/admin_1.php",
                log_id  => $self->{username},
                log_pwd => $self->{password}
            }
        );

        my $content = $res->{content};
        if ( $ENV{DEBUG} ) {
            print STDERR "$res->{status} $res->{reason}\n";

            while ( my ( $k, $v ) = each %{ $res->{headers} } ) {
                for ( ref $v eq 'ARRAY' ? @$v : $v ) {
                    print STDERR "$k: $_\n";
                }
            }

            print STDERR "$content\n";
        }

        if ( $content =~ m{location\.replace\('http://dressfree\.net/service/admin_1\.php'\)} ) {
            ## success
            $cookie->spew( join "\n", $cookiejar->dump_cookies );
        }
        else {
            ## fail
            return;
        }
    }

    bless $self, $class;
    return $self;
}

=head2 update_status( $reut_num, $status )

    my $success = $client->update_status($rent_num, $EW_STATUS_COMPLETE);

아래의 상태 값 상수는 C<OpenCloset::Events::EmploymentWing> 를 사용하면 자동으로 import 됩니다.

=over

=item *

C<$EW_STATUS_BOOKING> - 예약중

=item *

C<$EW_STATUS_COMPLETE> - 대여완료

=item *

C<$EW_STATUS_RETURNED> - 회수완료

=item *

C<$EW_STATUS_CANCEL> - 대여취소

=back

=cut

our $EW_STATUS_BOOKING  = 1;
our $EW_STATUS_COMPLETE = 2;
our $EW_STATUS_RETURNED = 3;
our $EW_STATUS_CANCEL   = 4;

sub update_status {
    my ( $self, $rent_num, $status ) = @_;
    return unless $rent_num;
    return unless $status;

    my $res = $self->{http}->post_form(
        "$HOST/dev/ajax_update.php",
        {
            uptype => 'online_state',
            val1   => $rent_num,
            val2   => $status,
        }
    );

    my $content = $res->{content};
    print STDERR "$content\n" if $ENV{DEBUG};

    return $res if $content =~ m/true/;
    return;
}

1;

__END__

=head1 COPYRIGHT and LICENSE

The MIT License (MIT)

Copyright (c) 2017 열린옷장

=cut
