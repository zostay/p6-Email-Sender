use v6;

unit module Email::Sender::EasyTransport;

use Email::Sender::Transport;

sub _rewrite-class(Str:D $transport-class is copy) {
    if $transport-class !~~ s/^ '='// and !$transport-class.contains(':') {
        $transport-class = "Email::Sender::Transport::$transport-class";
    }

    return $transport-class;
}

our sub easy-transport($transport-class is copy, %arg) is export {
    if $transport-class ~~ Str {
        $transport-class = _rewrite-class($transport-class);

        try require ::($transport-class);
        if ::($transport-class) ~~ Failure {
            die "unable to load Email::Sender::Transport $transport-class";
        }

        if ::($transport-class) !~~ Email::Sender::Transport {
            die "the transport class $transport-class does not do the required Email::Sender::Transport role";
        }
    }

    ::($transport-class).new(|%arg)
}
