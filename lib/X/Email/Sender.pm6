use v6;

use Email::Sender::Role::CommonSending;

unit package X::Email;

class Sender is Exception does X::Email::Sender::CommonSending {
    subset NonBlankStr of Str where /\S/;

    has NonBlankStr $.message;
    has Bool $.temporary;
    has Bool $.permanent;

    multi method new(Str $message) {
        self.bless(:$message);
    }

    multi method new(NonBlankStr $message, Bool:D :$permanent!) is default {
        self.bless(:$message, :permanent, :!temporary);
    }

    multi method new(NonBlankStr $message, Bool:D :$temporary!) is default {
        self.bless(:$message, :!permanent, :temporary);
    }

    method code(--> Int) { Nil }

}

class Sender::Multi is X::Email::Sender {
    has X::Email::Sender @.failures is required;

    method recipients(--> Seq) {
        gather for @!failures {
            .take for @(.recipients);
        }
    }

    method temporary(--> Bool:D) { ?all(@!failures).temporary }
    method permanent(--> Bool:D) { ?all(@!failures).permanent }
}

