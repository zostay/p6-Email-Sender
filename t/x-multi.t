use v6;

use Test;

use X::Email::Sender;
use Email::Sender::Transport::SMTP;

plan 4;

class X::Email::Sender::Testing is X::Email::Sender {
    has $.permanent;
    has $.temporary;

    multi method new($message, :$permanent!) is default {
        self.bless(:$message, :$permanent, :!temporary);
    }

    multi method new($message, :$temporary!) is default {
        self.bless(:$message, :!permanent, :$temporary);
    }
}

my $fail = X::Email::Sender.new('generic');
my $perm = X::Email::Sender::Testing.new('permanent', :permanent);
my $temp = X::Email::Sender::Testing.new('temporary', :temporary);

subtest 'multi-single-basic', {
    my $multi-fail = X::Email::Sender::Multi.new(
        message  => 'multifail',
        failures => [ $fail ],
    );

    isa-ok $multi-fail, X::Email::Sender;
    is $multi-fail.permanent, False;
    is $multi-fail.temporary, False;
}

subtest 'multi-single-perm', {
    my $multi-perm = X::Email::Sender::Multi.new(
        message  => 'multifail',
        failures => [ $perm ],
    );

    isa-ok $multi-perm, X::Email::Sender;
    is $multi-perm.permanent, True;
    is $multi-perm.temporary, False;
}

subtest 'multi-single-temp', {
    my $multi-temp = X::Email::Sender::Multi.new(
        message  => 'multifail',
        failures => [ $temp ],
    );

    isa-ok $multi-temp, X::Email::Sender;
    is $multi-temp.permanent, False;
    is $multi-temp.temporary, True;
}

subtest 'multi-multi', {
    my $multi-mixed = X::Email::Sender::Multi.new(
        message  => 'multifail',
        failures => [ $fail, $perm, $temp ],
    );

    isa-ok $multi-mixed, X::Email::Sender;
    is $multi-mixed.permanent, False;
    is $multi-mixed.temporary, False;
}

done-testing;
