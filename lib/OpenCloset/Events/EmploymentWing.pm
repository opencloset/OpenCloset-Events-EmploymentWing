package OpenCloset::Events::EmploymentWing;

use utf8;
require Exporter;
@ISA    = qw/Exporter/;
@EXPORT = qw/$EW_STATUS_BOOKING $EW_STATUS_COMPLETE $EW_STATUS_RETURNED $EW_STATUS_CANCEL/;

use strict;
use warnings;

use HTTP::Tiny;

=encoding utf8

=head1 NAME

OpenCloset::Events::EmploymentWing - 취업날개 API(?) client

=head1 SYNOPSIS

    use OpenCloset::Events::EmploymentWing;
    my $client  = OpenCloset::Events::EmploymentWing->new;
    my $success = $client->update_status($rent_num, $EW_STATUS_COMPLETE);

=cut

our $HOST = "http://dressfree.net";

=head1 METHODS

=head2 new

    my $client = OpenCloset::Events::EmploymentWing->new;

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        http => HTTP::Tiny->new(
            timeout         => 5,
            default_headers => { agent => __PACKAGE__ }
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

    my $content = $res->{content};
    print STDERR "$content\n" if $ENV{DEBUG};

    return $res if $content =~ m/true/;
    return;
}

=head2 update_booking_datetime( $rent_num, $datetime )

인증없이 사용할 수 있음

=cut

sub update_booking_datetime {
    my ( $self, $rent_num, $datetime ) = @_;
    return unless $rent_num;
    return unless $datetime;
}

1;

__END__

=head1 COPYRIGHT and LICENSE

The MIT License (MIT)

Copyright (c) 2017 열린옷장

=cut
