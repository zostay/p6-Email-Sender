use v6;

use Test;

use Email::Simple;
use Email::MIME;
use Email::Sender::Transport::Maildir;
use Temp::Path;

plan 10;

my $message = 't/messages/simple.msg'.IO.slurp;
my $maildir = make-temp-dir;

my $sender = Email::Sender::Transport::Maildir.new(
    dir => $maildir,
);

for ^2 {
    my $result = $sender.send(
        Email::MIME.new($message),
        to   => [ 'rjbs@example.com' ],
        from => 'rjbs@example.biz',
    );

    isa-ok $result, Email::Sender::Success, 'delivery result';
    ok $result.filename.starts-with($maildir),
        "the result filenaeme begins with the maildir";

    ok $result.filename.f, '... and exists';
}

my $new = $maildir.add('new');

ok $new.d, 'maildir ./new directory exists now';

my @files = $new.dir;
is @files.elems, 2, 'there are now two delivered messages in the Maildir';

my $simple = Email::Simple.new(@files[0].slurp);

is $simple.header('X-Email-Sender-To'), 'rjbs@example.com', 'env info in hdr';
is $simple.header('Lines'), 4, 'we counted lines correctly';

done-testing;
