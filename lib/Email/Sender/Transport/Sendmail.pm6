use v6;

use Email::Sender::Transport;
use X::Email::Sender;

unit class Email::Sender::Transport::Sendmail does Email::Sender::Transport;

has IO::Path $.sendmail;

our sub find-sendmail(Str:D $program-name = 'sendmail' --> IO::Path:D) {
    my @path = $*SPEC.path.map(*.IO);

    if $program-name eq 'sendmail' {
        # For 'real' sendmail we will look in common locations -- rjbs, 2009-07-12
        push @path, '/usr/sbin'.IO;
        push @path, '/usr/lib'.IO;
    }

    for @path -> $dir {
        my $sendmail = $dir.add($program-name);

        # TODO Is this $*KERNEL.name check really necessary?
        return $sendmail
            if $*KERNEL.name eq 'win32' ?? $sendmail.f !! $sendmail.x;
    }

    die "couldn't find a sendmail executable";
}

submethod BUILD(
    IO::Path :$!sendmail = find-sendmail('sendmail'),
) {
}

method !sendmail-proc(Str:D $email, :$from, :@to --> Proc) {
    my $p = run $!sendmail, '-i', '-f', $from, '--', |@to, :in;
    $p.in.print($email);
    $p.in.close;

    if !$p {
        die X::Email::Sender.new("couldn't run sendmail ($!sendmail): exited with code ($p.exitcode())")
    }

    CATCH {
        when X::Proc::Unsuccessful {
            die X::Email::Sender.new("couldn't run sendmail ($!sendmail): $_");
        }
    }

    $p;
}

method send-email(Email::MIME $email, :$from, :@to) {
    my $serial-email = $email.Str;
    $serial-email ~~ s/\x0d\x0a/\x0a/ unless $*KERNEL.name eq 'win32';

    my $p = self!sendmail-proc($serial-email, :@to, :$from);


    self.success;
}
