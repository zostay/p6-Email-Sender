use v6;

unit module Email::Sender::EasyTransport;

sub _rewrite-class(Str:D $transport-class is copy) {
    if $transport-class ~~ s/^ '='// and !$transport-class.contains(':') {
        $transport-class = "Email::Sender::Transport::$transport-class";
    }

    return $transport-class;
}

sub easy-transport($transport-class is copy, %arg) is export {
    if $transport-class ~~ Str {
        $transport-class = _rewrite-class($transport-class);
        require ::($transport-class);
    }

    ::($transport-class).new(|%arg);
}
