use v6

use Email::Sender::Transport;

unit class Email::Sender::Transport::Mbox does Email::Sender::Transport;

has IO::Path $.filename = $*CWD.add('mbox');

method send-email(Email::MIME $email, :@to, :$from --> Email::Sender::Success:D) {
    my $fh = self!open-fh($.filename);

    try {
        if $fh.tell > 0 {
            $fh.print("\n");
        }

        $fh.print: self!from-line($email, $from);
        $fh.print: self!escape-from-body($email);
        $fh.print("\n") unless $email.Str.ends-with("\n");

        self!close-fh($fh);

        CATCH {
            when X::IO {
                die "couldn't write to $.filename: $_";
            }
        }
    }
}

method !open-fh(IO::Path $filename --> IO::Handle:D) {
    my $fh = $filename.open(:w, :a, :bin);
    self!getlock($fh, $filename);
    $fh.seek(0, SeekFromEnd);
    $fh;
}

method !close-fh(IO::Handle $fh) {
    $fh.unlock;
    $fh.close;
}

method !escape-from-body($email) {
    my $body = $email.body;
    $body ~~ s:g/^ ("From ")/> $0/;
    $email.as-string;
}

my @dow = <Sun Mon Tue Wed Thu Fri Sat>;
my @mon = <Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec>;
method !from-line($email, $from) {
    my $now = DateTime.now;
    my $fromtime = sprintf "%s %s %2d %02d:%02d:%02d %04d",
        @dow[$now.day-of-week % 7],
        @mon[$now.month-1],
        $now.day,
        $now.hour,
        $now.minute,
        $now.second,
        $now.year;

    "From $from  $fromtime\n";
}

method !getlock($fh, $fn) {
    for ^10 {
        return if $fh.lock(:non-blocking);
        sleep $_;
    }

    die "couldn't lock file $fn";
}
