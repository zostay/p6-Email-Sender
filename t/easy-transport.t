use v6;

use Test;

use Email::Sender::EasyTransport;

my $test-transport = easy-transport('Test', %());
isa-ok $test-transport, 'Email::Sender::Transport::Test';

my $sendmail-transport = easy-transport('Sendmail', %(:sendmail('goofball'.IO)));
isa-ok $sendmail-transport, 'Email::Sender::Transport::Sendmail';
is $sendmail-transport.sendmail, 'goofball'.IO;

my $print-transport = easy-transport('=Email::Sender::Transport::Print', %());
isa-ok $print-transport, 'Email::Sender::Transport::Print';

done-testing;
