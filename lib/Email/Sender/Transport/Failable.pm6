use v6;

use Email::Sender::Transport::Wrapper;
use Email::MIME;

unit class Email::Sender::Transport::Failable is Email::Sender::Transport::Wrapper;

has Callable @.failure-conditions;

method fail-if(&cond) { @!failure-conditions.push: &cond }
method clear-failure-conditions() { @!failure-conditions = () }

method send-email(Email::MIME $email, :@to, :$from --> Email::Sender::Success:D) {
    for @.failure-conditions -> &cond {
        my $reason = cond($email, :@to, :$from);
        next unless $reason;
        die $reason ~~ Exception ?? $reason !! X::Email::Sender.new($reason);
    }

    self.Email::Sender::Transport::Wrapper::send-email($email, :@to, :$from);
}
