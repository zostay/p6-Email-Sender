use v6;

unit role Email::Sender;

sub send { ... }

=begin pod

=head1 NAME

Email::Sender - a library for sending email

=head1 SYNOPSIS

    my $message = Email::MIME.create( ... );

    use Email::Sender::Simple qw( sendmail );
    use Email::Sender::Transport::SMTP qw();

    try {
        sendmail(
            $message,
            %(
                from      => $SMTP_ENVELOPE_FROM_ADDRESS,
                transport => Email::Sender::Transport::SMTP.new(
                    host => $SMTP_HOSTNAME,
                    port => $SMTP_PORT,
                ),
            )
        );

        CATCH {
            warn "sending failed: $_";
        }
    }

=head1 OVERVIEW

=head1 IMPLEMENTING

=end pod
