use v6;

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

    method send(Email::MIME $email, *%env) {
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
        %new-env<to>   = @to.grep(*.defined).Array;
        %new-env<from> = $from;
        %new-env;
    }

    method success(--> Email::Sender::Success:D) {
        Email::Sender::Success.new;
    }
}
