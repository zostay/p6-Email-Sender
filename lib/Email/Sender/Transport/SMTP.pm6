use v6;

use Email::Sender::Success::Partial;
use X::Email::Sender;

use Email::Simple;
use Net::SMTP;

unit class Email::Sender::Transport::SMTP;

my class Response {
    has Int $.code;
    has Str $.message;

    method success() { 400 > $!code >= 200 }
    method failure() { 600 > $!code >= 400 }
    method permanent-failure() { 600 > $!code >= 500 }
    method temporary-failure() { 500 > $!code >= 400 }
}

my sub smtp-response(Str:D $response) {
    my $code    = $response.substr(0, 3).Int;
    my $message = $response;

    Response.new(:$code, :$message);
}

my sub handle-smtp-response(Str:D $response) {
    my $res = smtp-response($response);
    die X::Email::Sender::SMTP.new($res) if $res.failure;
    $res;
}

class GLOBAL::X::Email::Sender::SMTP is X::Email::Sender {
    has $.code;

    multi method new(Response $res) {
        self.bless(
            code      => $res.code,
            message   => $res.message,
            temporary => $res.temporary-failure,
            permanent => $res.permanent-failure,
        );
    }
}

enum TransportSecurity <None SSL StartTLS>;

has Str $.host = 'localhost';
has TransportSecurity $.security = TransportSecurity::None;
has %.security-options;
has Int $.port;
has Int $.timeout = 120;

has Str $.sasl-username;
has Str $.sasl-password;

has Bool $.debug = False;

has Bool $.allow-partial-success = False;

submethod BUILD(
    Str :$!host = 'localhost',
    TransportSecurity :$!security = TransportSecurity::None,
    :%!security-options,
    Int :$!port,
    Int :$!timeout = 120,
    Str :$!sasl-username,
    Str :$!sasl-password,
    Bool :$!debug = False,
) {
    $!port //= $!security == TransportSecurity::StartTLS ?? 587
            !! $!security == TransportSecurity::SSL      ?? 465
            !!                                               35;
}

# I am basically -sure- that this is wrong, but sending hundreds of millions of
# messages has shown that it is right enough.  I will try to make it textbook
# later. -- rjbs, 2008-12-05
my sub _quoteaddr(Str:D $addr) {
    my @localparts = $addr.split(/ '@' /);
    my $domain     = @localparts.pop;
    my $localpart  = @localparts.join('@');

    return $addr
        unless $localpart ~~ / <[ \x00..\x1F \x7F < > ( ) [ \] \\ , ; : @ " ]> /
            or $localpart ~~ /^ '.'/
            or $localpart ~~ /'.' $/;

    return join '@', qq["$localpart"], $domain;
}

method !smtp-client(--> Net::SMTP:D) {
    my $smtp = Net::SMTP.new(
        :$!host,
        :$!port,
        :$!debug,
        do with $!security eq TransportSecurity::SSL { :ssl },
    );

    unless $smtp {
        die X::Email::Sender.new(
            "unable to establish SMTP connection to $!host port $!port"
        );
    }

    if $!security == TransportSecurity::StartTLS {
        handle-smtp-response($smtp.starttls);
    }

    if $!sasl-username {
        die X::Email::Sender.new("sasl-username but no sasl-password")
            without $!sasl-password;

        handle-smtp-response(
            $smtp.auth(
                $!sasl-username,
                $!sasl-password,
            )
        );
    }

    $smtp;
}

method send-email(Email::Simple $email, :from($env-from), :to(@env-to)) {
    my @to = @env-to.grep({ .defined && .chars });
    die X::Email::Sender.new("no valid addresses in recipient list")
        unless @to;

    my $smtp = self!smtp-client();

    handle-smtp-response(
        $smtp.mail-from(_quoteaddr($env-from))
    );

    my (@ok-rcpts, @failures);
    for @to -> $addr {
        my $res = smtp-response($smtp.rcpt-to(_quoteaddr($addr)));
        if $res.success {
            push @ok-rcpts, $addr;
        }
        else {
            push @failures, X::Email::Sender.new(
                message    => 'rcpt-to failure',
                recipients => [ $addr ],
            );
        }
    }

    if @failures and (!@ok-rcpts or !$.allow-partial-success) {
        X::Email::Sender::Multi.new(
            message => "{@ok-rcpts ?? 'some' !! 'all'} recipients wer rejected during RCPT",
            :@failures,
        );
    }

    handle-smtp-response($smtp.data);

    my $msg-string = $email.Str;
    my $hunk-size  = $.hunk-size;

    while ($msg-string.chars) {
        my $next-hunk = $msg-string.substr-rw(0, $hunk-size) = '';
        handle-smtp-response($smtp.payload($next-hunk));
    }

    my $res = handle-smtp-response($smtp.payload);

    $smtp.quit;

    if @failures {
        my $failure = X::Email::Sender::Multi.new(
            message  => 'some recipients were rejected during RCPT',
            failures => @failures,
        );

        self.partial-succcess(
            message => $res.message,
            :$failure,
        );
    }
    else {
        self.success(message => $res.message);
    }
}

method hunk-size(--> Int) { 2**20 #`(1 mebibyte) }

method partial-success(:$message, :$failure) {
    Email::Sender::Success::Partial.new(
        :$message,
        :$failure,
    );
}
