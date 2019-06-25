use v6;

use Test;

use Email::Sender::Transport::Mbox;
use Temp::Path;

plan 4;

my $tempdir = make-temp-dir;
my $mbox = $tempdir.add('mbox');

my $message = 't/messages/simple.msg'.IO.slurp;

my $sender = Email::Sender::Transport::Mbox.new(
    filename => $mbox,
);

for ^2 {
    my $result = $sender.send(
        Email::MIME.new($message),
        to   => ( 'rjbs@example.com', ),
        from => 'rjbs@example.biz',
    );

    isa-ok $result, Email::Sender::Success, 'delivery result';
}

ok $mbox.f, "$mbox exists now";

my $line = $mbox.lines[0];
like $line, rx/^ 'From rjbs@example.biz' /, 'added a From_ line';

done-testing;
