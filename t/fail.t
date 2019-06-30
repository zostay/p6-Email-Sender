use v6;

use Test;
use X::Email::Sender;

subtest 'string-alone' => {
    my $fail = X::Email::Sender.new('message');
    isa-ok $fail, X::Email::Sender;
    is $fail.message, 'message', 'string alone -> message';
}

subtest 'string-permanent' => {
    my $fail = X::Email::Sender.new('message', :permanent);
    isa-ok $fail, X::Email::Sender;
    is $fail.message, 'message', 'got message';
    is $fail.permanent, True, 'failure is perm';
    is $fail.temporary, False, 'failure is not temp';
}

subtest 'string-temporary' => {
    my $fail = X::Email::Sender.new('message', :temporary);
    isa-ok $fail, X::Email::Sender;
    is $fail.message, 'message', 'got message';
    is $fail.permanent, False, 'failure is not perm';
    is $fail.temporary, True, 'failure is temp';
}

done-testing;
