use v6;

use Email::Sender::Transport;

unit class Email::Sender::Transport::Null does Email::Sender::Transport;

method send-email(Email::Simple $, *%) {
    self.success;
}
