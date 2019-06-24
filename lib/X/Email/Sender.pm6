use v6;

use Email::Sender::Role::CommonSending;

unit package X::Email;

class Sender is Exception does X::Email::Sender::CommonSending {
    trusts Email::Sender::Role::CommonSending;

    subset NonBlankStr of Str where /\S/;

    has NonBlankStr $.message;

    multi method new(Str $message) {
        self.bless(:$message);
    }

    method code(--> Int) { Nil }
    method temporary(--> Bool:D) { False }
    method permanent(--> Bool:D) { False }

}

class Sender::Multi is X::Email::Sender {
    has X::Email::Sender @.failures is required;

    method recipients(--> Seq) {
        gather for @!failures {
            .take for @(.recipients);
        }
    }

    method temporary(--> Bool:D) { all(@!failures).temporary }
    method permanent(--> Bool:D) { all(@!failures).permanent }
}

