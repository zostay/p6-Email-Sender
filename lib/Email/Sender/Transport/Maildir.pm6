use v6;

use Email::Sender::Transport;
use X::Email::Sender;

unit class Email::Sender::Transport::Maildir does Email::Sender::Transport;

class GLOBAL::Email::Sender::Success::Maildir is Email::Sender::Success {
    has IO::Path $.filename is required;
}

my $MAILDIR-TIME    = 0;
my $MAILDIR-COUNTER = 0;

has Bool $.add-lines-header = True;
has Bool $.add-envelope-headers = True;

has IO::Path $.dir = $*CWD.add('Maildir');

method send-email(Email::MIME $email, :to(@orig-to), :$from --> Email::Sender::Success::Maildir:D) {
    my $dupe = Email::MIME.new($email.Str);

    my @to;
    if $!add-envelope-headers {
        $dupe.header-set('X-Email-Sender-From',
            do with $from { $from } else { '-' }
        );

        @to = @orig-to.grep(*.defined);
        $dupe.header-set('X-Email-Sender-To',
            do if @to { @to } else { '-' }
        );
    }

    self!ensure-maildir-exists;

    self!add-lines-header($dupe) if $!add-lines-header;
    self!update-time;

    my $filename = self!deliver-email($dupe);

    return Email::Sender::Success::Maildir.new(
        :$filename,
    );
}

method !ensure-maildir-exists() {
    for <cur tmp new> -> $dir-name {
        my $subdir = $!dir.add($dir-name);
        next if $subdir.d;

        try {
            $subdir.mkdir;

            CATCH {
                when X::IO::Mkdir {
                    die X::Email::Sender.new("couldn't create $subdir: $_");
                }
            }
        }
    }
}

method !add-lines-header($email) {
    return if $email.header("Lines");
    my $lines = $email.body-str.lines.elems;
    $email.header-set("Lines", $lines);
}

method !update-time() {
    my $time = DateTime.now.posix;
    if $MAILDIR-TIME != $time {
        $MAILDIR-TIME    = $time;
        $MAILDIR-COUNTER = 0;
    }
    else {
        $MAILDIR-COUNTER++;
    }
}

method !deliver-email($email) {
    my ($tmp-filename, $tmp-fh);
    try {
        ($tmp-filename, $tmp-fh) = self!deliver-fh;

        my $string = $email.Str;
        $string ~~ s:g/\x0D\x0A/\x0A/;
        $tmp-fh.print($string);
        $tmp-fh.close;

        CATCH {
            when X::IO {
                die X::Email::Sender.new("error writing $tmp-filename: $_");
            }
        }
    }

    my $target-name = $!dir.add('new').add($tmp-filename);

    try {
        rename $!dir.add('tmp').add($tmp-filename), $target-name;

        CATCH {
            when X::IO {
                die X::Email::Sender.new("could not move $tmp-filename from tmp to new");
            }
        }
    }

    $target-name;
}

method !deliver-fh() {
    my $hostname = $*KERNEL.hostname;

    my ($filename, $fh);
    until $fh {
        $filename = join q{.}, $MAILDIR-TIME, $*PID, ++$MAILDIR-COUNTER, $hostname;
        my $path = $!dir.add('tmp').add($filename);

        try {
            $fh = $path.open(:create, :exclusive, :w);

            CATCH {
                when X::IO {
                    die X::Email::Sender.new("cannot create $path for delivery: $_");
                }
            }
        }
    }

    $filename, $fh;
}
