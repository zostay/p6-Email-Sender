use v6;

use Email::Sender::Transport;

unit class Email::Sender::Transport::Print does Email::Sender::Transport;

has IO::Handle $.handle = $*OUT;

method send-email(Email::Simple $email, :@to, :$from) {
    $!handle.say("ENVELOPE TO  : {@to.join(', ')}");
    $!handle.say("ENVELOPE FROM: {$from.defined ?? $from !! '-'}");
    $!handle.say("{'-' x 10} begin message");
    $!handle.say($email.Str);
    $!handle.say("{'-' x 10} end message");

    self.success;
}
