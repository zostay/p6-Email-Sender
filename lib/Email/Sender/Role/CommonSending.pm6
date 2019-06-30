use v6;

use Email::Simple;
use Email::MIME;
use Email::Sender;
use Email::Sender::Success;

role Email::Sender::Role::CommonSending { ... }

role X::Email::Sender::CommonSending {
    has @!recipients;

    method recipients(--> List) { @!recipients.List }

    method set-recipients(@recipients) {
        die "recipients already set" if @!recipients;
        @!recipients = @recipients;
    }
}

role Email::Sender::Role::CommonSending does Email::Sender {

    method send-email { ... }

    multi method send(Str $email, *%env) {
        self.send(Email::MIME.new($email), |%env);
    }

    multi method send(Email::Simple $email, *%env) {
        my %envelope = self.prepare-envelope(|%env);

        try {
            return self.send-email($email, |%envelope);

            CATCH {
                when X::Email::Sender::CommonSending {
                    .set-recipients(%envelope<to>)
                        if !.recipients;
                    .rethrow;
                }
            }
        }
    }

    method prepare-envelope(:@to, :$from --> Hash) {
        my %new-env;
        %new-env<to>   = .grep(*.defined).Array with @to;
        %new-env<from> = $_ with $from;
        %new-env;
    }

    method success(--> Email::Sender::Success:D) {
        Email::Sender::Success.new;
    }
}
