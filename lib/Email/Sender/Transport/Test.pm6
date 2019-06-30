use v6;

use Email::Sender::Transport;
use X::Email::Sender;
use Email::Simple;

unit class Email::Sender::Transport::Test does Email::Sender::Transport;

has Bool $.all-partial-success = False;

method recipient-failure($to) { }
method delivery-failure(Email::Simple $email, :@to, :$from) { }

class Delivery {
    has Email::Simple $.email;
    has %.envelope;
    has Str @.successes;
    has X::Email::Sender @.failures;
}

has Delivery @.deliveries;

method delivery-count(--> Int:D) { @.deliveries.elems }
method record-delivery(|c) { @.deliveries.push: Delivery.new(|c) }
method shift-deliveries(--> Delivery) { @.deliveries.shift }
method clear-deliveries() { @.deliveries = () }

method send-email(Email::Simple $email, :@to, :$from --> Email::Sender::Success) {
    my @failures;
    my @successes;

    if self.delivery-failure($email, :@to, :$from) -> $failure {
        die $failure;
    }

    for @to -> $to {
        if self.recipient-failure($to) -> $failure {
            @failures.push: $failure;
        }
        else {
            @successes.push: $to;
        }
    }

    if @failures and ((@successes == 0) or (!$.allow-partial-success)) {
        die @failures[0] if @failures == 1 and @successes == 0;

        my $message = "{@successes ?? 'some' !! 'all'} recipients were rejected";

        die X::Email::Sender::Multi.new(:$message, :@failures);
    }

    self.record-delivery(
        :$email, :@successes, :@failures,
        envelope => %( :@to, :$from ),
    );

    if @failures {
        Email::Sender::Success::Partial.new(
            failure => X::Email::Sender::Multi.new(
                message  => 'some recipients were rejected',
                :@failures,
            ),
        );
    }
    else {
        self.success;
    }
}
