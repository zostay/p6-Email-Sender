use v6;

use Email::Sender::Transport;
use X::Email::Sender;

unit class Email::Sender::Transport::Sendmail does Email::Sender::Transport;

has IO::Path $.sendmail;

sub find-sendmail(Str:D $program-name = 'sendmail' --> IO::Path:D) {
    my @path = $*SPEC.path.map(*.IO);

    if $program-name eq 'sendmail' {
        # For 'real' sendmail we will look in common locations -- rjbs, 2009-07-12
        push @path, '/usr/sbin'.IO;
        push @path, '/usr/lib'.IO;
    }

    for @path -> $dir {
        my $sendmail = $dir.add($program-name);
        return $sendmail if $sendmail.x;
    }

    die "couldn't find a sendmail executable";
}

submethod BUILD(
    :$!sendmail = find-sendmail('sendmail'),
) {
}

method !sendmail-proc(:$from, :@to --> Proc) {
    my $prog = $!sendmail;

    my $p = run $prog, '-i', '-f', $from, '--', |@to, :in;

    die X::Email::Sender.new("couldn't run to sendmail ($prog): $!")
        unless $p;

    return $p;
}

method send-email(Email::MIME $email, :$from, :@to) {
    my $p = self!sendmail-proc(:@to, :$from);

    my $serial-email = $email.Str;
    $serial-email ~~ s/\x0d\x0a/\x0a/;

    $p.in.print($serial-email)
        or die X::Email::Sender.new("couldn't send message to sendmail: $!");

    $p.in.close;

    self.success;
}
