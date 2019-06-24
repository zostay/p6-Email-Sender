use v6;

use Email::Address;
use Email::Sender;
use Email::Sender::EasyTransport;
use Email::Sender::Transport;
use Email::Sender::Role::CommonSending;
use X::Email::Sender;

unit class Email::Sender::Simple does Email::Sender::Role::CommonSending;

my Email::Sender::Transport $DEFAULT-TRANSPORT;
my Bool $DEFAULT-FROM-ENV;

method default-transport(--> Email::Sender::Transport:D) {
    return $DEFAULT-TRANSPORT if $DEFAULT-TRANSPORT;

    my $transport = self.transport-from-env;

    with $transport {
        $DEFAULT-FROM-ENV  = True;
        $DEFAULT-TRANSPORT = $transport;
    }
    else {
        $DEFAULT-FROM-ENV  = False;
        $DEFAULT-TRANSPORT = self.build-default-transport;
    }
}

method transport-from-env(Str:D $env-base = 'EMAIL_SENDER_TRANSPORT' --> Email::Sender::Transport) {
    my $transport-class = %*ENV{ $env-base };

    return unless $transport-class.defined && $transport-class.chars;

    my %arg;
    my %attrs = %*ENV.grep: {
        .key ~~ /^ $env-base _ <[ _ 0..9 A..Z a..z ]>+ $/
    };
    for %attrs.kv -> $key, $value {
        my $new-key = $key.substr($env-base.chars + 1);
        %arg{ $new-key.lc } = $value;
    }

    easy-transport($transport-class, %arg);
}

method build-default-transport(--> Email::Sender::Transport) {
    use Email::Sender::Transport::Sendmail;
    my $transport = try Email::Sender::Transport::Sendmail.new;

    return $transport if $transport;

    use Email::Sender::Transport::SMTP;
    Email::Sender::Transport::SMTP.new;
}

method reset-default-transport() {
    $DEFAULT-TRANSPORT = Nil;
    $DEFAULT-FROM-ENV  = Nil;
}

method prepare-envelope(*%arg) {
    my %env = callsame;

    %(
        %arg,
        %env,
    );
}

method send-email(
    Email::MIME $email,
    Email::Sender::Transport :$transport is copy,
    Str :to(@orig-to),
    Str :from($orig-from),
    --> Email::Sender::Success:D
) {
    $transport //= self.default-transport;

    die "transport $transport not safe for use with Email::Sender::Simple"
        unless $transport.is-simple;

    my (@to, $from) = self!get-to-from($email, :to(@orig-to), :from($orig-from));

    die X::Email::Sender::Permanent.new('no recipients') unless  @to;
    die X::Email::Sender::Permanent.new('no sender')     without $from;

    $transport.send($email, :@to, :$from);
}

method try-to-send(
    Email::MIME $email,
    Email::Sender::Transport :$transport is copy,
    Str :@to,
    Str :$from,
    --> Email::Sender::Success:_
) {
    try {
        return self.send($email, :@to, :$from);

        CATCH {
            when X::Email::Sender {
                return;
            }
            default {
                .rethow;
            }
        }
    }
}

method !get-to-from($email, :@to, :$from) {
    unless @to {
        my @to-addrs = <to cc>
            .map({ $email.get-header($^header-name) })
            .map({ Email::Address.parse(%^to) })
            .grep(*.defined)
            .map(*.address);
    }

    my $derived-from = $from;
    without $from {
        ($derived-from) = <from>
            .map({ $email.get-header($^header-name) })
            .map({ Email::Address.parse($^from) })
            .grep(*.defined)
            .map(*.address);
    }

    \(@to, $derived-from);
}
