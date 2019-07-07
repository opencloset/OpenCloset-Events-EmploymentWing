package OpenCloset::Events::EmploymentWing;

use utf8;
require Exporter;
@ISA    = qw/Exporter/;
@EXPORT = qw/$EW_STATUS_BOOKING $EW_STATUS_COMPLETE $EW_STATUS_RETURNED $EW_STATUS_CANCEL/;

use strict;
use warnings;

use Encode qw/decode_utf8/;
use HTTP::CookieJar;
use HTTP::Tiny;
use Mojo::DOM;

=encoding utf8

=head1 NAME

OpenCloset::Events::EmploymentWing - 취업날개 API(?) client

=head1 SYNOPSIS

    use OpenCloset::Events::EmploymentWing;
    my $client  = OpenCloset::Events::EmploymentWing->new;
    my $success = $client->update_status($rent_num, $EW_STATUS_COMPLETE);

=cut

our $HOST = "https://dressfree.net";

=head1 METHODS

=head2 new

    my $client = OpenCloset::Events::EmploymentWing->new;

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        username => $args{username} || '',
        password => $args{password} || '',
        http     => HTTP::Tiny->new(
            timeout         => 5,
            default_headers => { agent => __PACKAGE__ },
            cookie_jar      => HTTP::CookieJar->new,
        )
    };

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

    ## https://github.com/opencloset/opencloset/issues/1584
    ## redirect fallback
    if ($res->{status} == 302 and $res->{headers}{location}) {
        my $url = $res->{headers}{location};
        $res = $self->{http}->post_form(
            $url,
            {
                uptype => 'online_state',
                val1   => $rent_num,
                val2   => $status,
            }
        );
    }

    my $content = $res->{content};
    print STDERR "$content\n" if $ENV{DEBUG};

    return $res if $content =~ m/true/;
    return;
}

=head2 update_booking_datetime( $rent_num, $datetime, $online?, $exist? )

    my $datetime = $order->booking->date;
    ## 최초예약시
    my $success = $client->update_booking_datetime($rent_num, $datetime);

    ## 예약시간 변경시
    my $success = $client->update_booking_datetime($rent_num, $datetime, undef, 1);

=cut

sub update_booking_datetime {
    my ( $self, $rent_num, $datetime, $online, $exist ) = @_;
    return unless $rent_num;
    return unless $datetime;

    my $ymd = $datetime->ymd;
    my $hms = $datetime->hms;
    ## https://github.com/opencloset/opencloset/issues/1256
    my $params = { rent_num => $rent_num, rcv_type => '' };
    if ($online) {
        $params->{deli_date} = $ymd;
    }
    else {
        $params->{rent_date} = $ymd;
        $params->{rent_time} = $hms;
    }

    $params->{rcv_type} = 'm_date' if $exist;

    my $res = $self->{http}->post_form(
        "$HOST/theopencloset/api_rentRcv.php",
        $params
    );

    unless ( $res->{success} ) {
        warn "Failed call to update booking datetime: rent_num($rent_num), rent_date($ymd), rent_time($hms)";
        return;
    }

    return $res;
}

=head2 extend_period( $rent_num, $n, $desc )

    my $success = $client->extend_period($rent_num, 2, '대여기간 +6d');

=cut

sub extend_period {
    my ( $self, $rent_num, $n, $desc ) = @_;
    return unless $n;
    return unless $desc;

    $self->_auth;

    my $res     = $self->{http}->get("http://dressfree.net/service/admin_3_v.php?rent_num=$rent_num");
    my $content = decode_utf8( $res->{content} );
    warn "$content\n" if $ENV{DEBUG};

    my %params = ( p_history => $desc );
    my $dom = Mojo::DOM->new($content);
    for my $input ( $dom->find('form[name="onlineForm"] input')->each ) {
        $params{ $input->{name} } = $input->{value};
    }

    for ( 1 .. $n ) {
        my $res = $self->{http}->post_form( "http://dressfree.net/dev/penalty_ok.php", \%params );
        my $content = $res->{content};
        warn "$content\n" if $ENV{DEBUG};
    }

    return 1; # 결과는 알 수 없다.
}

=head2 _auth

=cut

sub _auth {
    my $self = shift;
    return unless $self->{username};
    return unless $self->{password};

    my $res = $self->{http}->post_form(
        "$HOST/dev/login_ok.php",
        {
            log_id  => $self->{username},
            log_pwd => $self->{password},
        }
    );

    my $content = $res->{content};
    warn "$content\n" if $ENV{DEBUG};

    return $res if $content =~ m/main\.php/;
    return;
}

1;

__END__

=head1 COPYRIGHT and LICENSE

The MIT License (MIT)

Copyright (c) 2017 열린옷장

=cut
