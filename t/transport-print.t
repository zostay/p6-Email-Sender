use v6;

use Test;
use Email::Sender;
use Email::Sender::Transport::Print;

plan 4;

class CP is IO::Handle {
    has Str $.str = '';
    method say(*@_) { $!str ~= @_.join; $!str ~= "\n" }
}

my $xport = Email::Sender::Transport::Print.new(handle => CP.new);
does-ok $xport, Email::Sender::Transport;
isa-ok $xport, Email::Sender::Transport::Print;

my $message = q:to/END_MESSAGE/;
From: from@test.example.com
To: to@nowhere.example.net
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

--
sender
END_MESSAGE

my $want = qq:to/END_WANT/;
ENVELOPE TO  : rcpt@nowhere.example.net
ENVELOPE FROM: sender@test.example.com
---------- begin message
$message
---------- end message
END_WANT

my $result = $xport.send(
    Email::MIME.new($message),
    to   => [ 'rcpt@nowhere.example.net' ],
    from => 'sender@test.example.com',
);

isa-ok $result, Email::Sender::Success;
is $xport.handle.str, $want, 'what we expected got printed';

done-testing;
