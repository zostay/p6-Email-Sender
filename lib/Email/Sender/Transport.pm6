use v6;

use Email::Sender::Role::CommonSending;

unit role Email::Sender::Transport does Email::Sender::Role::CommonSending;

method is-simple(--> Bool:D) { !$.allow-partial-success }
method allow-partial-success { False }
