use v6;

use Test;

use Email::MIME;
use Email::Sender;
use Email::Sender::Transport::Null;

my $xport = Email::Sender::Transport::Null.new;
does-ok $xport, Email::Sender::Transport;
isa-ok $xport, Email::Sender::Transport::Null;

my $message-text = q:to/END_MESSAGE/;
From: sender@test.example.com
To: recipient@nowhere.example.net
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

--
sender
END_MESSAGE

my $message = Email::MIME.new($message-text);
my $result = $xport.send($message);
isa-ok $result, Email::Sender::Success;

done-testing;
