#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use FixMyStreet::App;
use FixMyStreet::Map;
use FixMyStreet::TestMech;
use DateTime;
use mySociety::Locale;

my $mech = FixMyStreet::TestMech->new;

mySociety::Locale::gettext_domain('FixMyStreet');

FixMyStreet::Map::set_map_class();
my $r = Catalyst::Request->new( { base => URI->new('/'), uri => URI->new('http://fixmystreet.com/test') } );

my $c = FixMyStreet::App->new( {
    request => $r,
});

$mech->delete_user('test@example.com');
my $user =
  FixMyStreet::App->model('DB::User')
  ->find_or_create( { email => 'test@example.com', name => 'Test User' } );
ok $user, "created test user";

my $dt = DateTime->now();


my $report = FixMyStreet::App->model('DB::Problem')->find_or_create(
    {
        postcode           => 'SW1A 1AA',
        council            => '2504',
        areas              => ',105255,11806,11828,2247,2504,',
        category           => 'Other',
        title              => 'Test 2',
        detail             => 'Test 2 Detail',
        used_map           => 't',
        name               => 'Test User',
        anonymous          => 'f',
        state              => 'fixed',
        confirmed          => $dt->ymd . ' ' . $dt->hms,
        lang               => 'en-gb',
        service            => '',
        cobrand            => 'default',
        cobrand_data       => '',
        send_questionnaire => 't',
        latitude           => '49.7668057243776',
        longitude          => '-7.55715980363992',
        user_id            => $user->id,
    }
);

for my $test ( 
    {
        state => 'fixed', 
        colour => 'G',
    },
    {
        state => 'fixed - user', 
        colour => 'G',
    },
    {
        state => 'fixed - council', 
        colour => 'G',
    },
    {
        state => 'confirmed', 
        colour => 'R',
    },
    {
        state => 'investigating', 
        colour => 'R',
    },
    {
        state => 'planned', 
        colour => 'R',
    },
    {
        state => 'in progress', 
        colour => 'R',
    },
) {
    subtest "pin colour for state $test->{state}" => sub {
        $report->state($test->{state});
        $report->update;

        my ( $pins, $around_map_list, $nearby, $dist ) =
            FixMyStreet::Map::map_pins( $c, 0, 0, 0, 0 );

        ok $pins;
        ok $around_map_list;
        ok $nearby;
        ok $dist;

        my $id = $report->id;
        my $colour = $test->{colour};

        like $pins, qr#<a [^>]* /report/$id [^>]*>[^>]*/i/pin$colour#x, 'pin colour';
    };
}

$mech->delete_user( $user );


done_testing();
