use v6;

use Email::Sender;
use Email::Sender::Success;
use X::Email::Sender;

unit class Email::Sender::Success::Partial is Email::Sender::Success;

has X::Email::Sender $.failure is required;
