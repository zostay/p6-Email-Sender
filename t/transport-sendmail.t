use v6;

use Test;

use Email::MIME;
use Email::Sender::Transport::Sendmail;
use Temp::Path;

plan 8;

constant $IS-WIN32 = $*KERNEL.name eq 'win32';

my $email = Email::MIME.new(q:to/EOF/);
To:   Casey West <casey@example.com>
From: Casey West <casey@example.net>
Subject: This should never show up in my inbox

blah blah blah
EOF

sub get-bin-name(IO::Path $bin-path --> IO::Path) {
    return $bin-path.add('sendmail.bat') if $IS-WIN32;
    $bin-path.add('sendmail');
}

my $bin-path     = $*CWD.add('t/util');
my $sendmail-bin = get-bin-name($bin-path);
my $bin-name     = $sendmail-bin.basename;
%*ENV<PATH>      = join $*DISTRO.path-sep, $sendmail-bin.dirname, %*ENV<PATH>;

lives-ok {
    my $path = Email::Sender::Transport::Sendmail::find-sendmail($bin-name);

    is $path, $sendmail-bin, "found (fake) sendmail at '$sendmail-bin'";
}

throws-like {
    my $sender = Email::Sender::Transport::Sendmail.new(
        sendmail => $*CWD.add('t/util/not-executable'),
    );

    $sender.send(
        $email,
        to   => [ 'devnull@example.com' ],
        from => 'devnull@example.biz',
    );
}, X::Email::Sender, message => /"couldn't run"/;

lives-ok {
    my $sender = Email::Sender::Transport::Sendmail.new(
        sendmail => $sendmail-bin,
    );

    my $result = $sender.send(
        $email,
        to   => [ 'devnull@example.com' ],
        from => 'devnull@example.biz',
    );

    ok $result, 'send() succeeded with executable t/util/sendmail';
}

lives-ok {
    my $logdir = make-temp-dir;
    temp %*ENV<EMAIL_SENDER_TRANSPORT_SENDMAIL_TEST_LOGDIR> = $logdir;
    my $sender = Email::Sender::Transport::Sendmail.new(
        sendmail => $sendmail-bin,
    );

    my $result = $sender.send(
        $email,
        to   => [ 'devnull@example.com' ],
        from => 'devnull@example.biz',
    );

    ok $result, 'send() succeeded with executable t/util/sendmail';

    my $log-file = $logdir.add('sendmail.log');
    if $log-file.f {
        like $log-file.slurp, /^^'From: Casey West'/, 'log contains From header';
    }
    else {
        flunk('cannot check sendmail log contents');
    }
}

done-testing;
