use v6;

use Test;

temp %*ENV<EMAIL_SENDER_TRANSPORT> = 'Test';
use Email::Sender::Simple :sendmail;
use Email::Sender::Transport::Test;

my $email = q:to/./;
From: V <number.5@example.com>
To: II <number.2@example.org>
Subject: jolly good show

Wot, wot!

--
v
.

my $result = Email::Sender::Simple.send($email);

isa-ok $result, Email::Sender::Success;

my $env-transport = Email::Sender::Simple.default-transport;
isa-ok $env-transport, Email::Sender::Transport::Test;
my @deliveries = $env-transport.deliveries;

is @deliveries.elems, 1, 'we sent one message';

is-deeply
    @deliveries[0].envelope,
    %(
        to   => [ 'number.2@example.org' ],
        from => 'number.5@example.com',
    ),
    'correct envelope deduced from message',
;

subtest 'ignore-given-transport-on-env-transport', {
    my $new-test = Email::Sender::Transport::Test.new;
    my $result = Email::Sender::Simple.send(
        $email,
        to        => [ 'devnull@example.com' ],
        transport => $new-test,
    );

    is $env-transport.delivery-count, 2,
        "we ignore the passed transport when we're using transport-from-env";

    is-deeply(
        $env-transport.deliveries[1].envelope,
        %(
            to   => [ 'devnull@example.com' ],
            from => 'number.5@example.com',
        ),
        'we stored teh right message for the second delivery',
    );
}

subtest 'handling-simple-failure' => {
    my $email = Email::Simple.new("Subject: foo\n\nbar\n");

    subtest 'send-fails' => {
        my $result;
        throws-like {
            $result = Email::Sender::Simple.send($email);
        }, X::Email::Sender;
        nok $result, 'we got no return value';
    }

    subtest 'try-send-fails-quietly' => {
        my $result;
        lives-ok {
            $result = Email::Sender::Simple.try-to-send($email);
        }
        nok $result, 'we got not return value';
    }
}

done-testing;
