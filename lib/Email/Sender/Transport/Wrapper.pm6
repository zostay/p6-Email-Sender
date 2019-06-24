use v6;

use Email::Sender::EasyTransport;
use Email::Sender::Transport;

unit class Email::Sender::Transport::Wrapper does Email::Sender::Transport;

has Email::Sender::Transport $.transport is required handles <send-email>;

method is-simple(--> Bool:D) { $.transport.is-simple }
method allow-partial-success(--> Bool:D) { $.allow-partial-success }

only method new(
    :$transport-class,
    Email::Sender::Transport :transport($explicit-transport),
    *%args,
    --> Email::Sender::Transport::Wrapper:D
) {
    if $transport-class {
        die "given both a transport aand transport-class"
            with $explicit-transport;

        my %transport-arg
            = %args.grep({ .key ~~ /^ transport_arg_ / })
                   .map({ .key.substr('transport_arg_'.chars) => .value });

        easy-transport($transport-class, %transport-arg);
    }
    else {
        $explicit-transport;
    }
}
