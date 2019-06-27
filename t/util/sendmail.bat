@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl6 -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/env perl6
#line 15
use v6;

use Temp::Path;

my $dir = %*ENV<EMAIL_SENDER_TRANSPORT_SENDMAIL_TEST_LOGDIR> 
       // make-temp-dir;

my $logfile = $dir.add('sendmail.log');

my $input = $*IN.slurp;

my $fh = $logfile.open(:w);

$fh.say: "CLI args: @ARGV[]";
if $input.defined && $input.chars {
  $fh.say: "Executed with input on STDIN\n$input";
} else {
  $fh.say: "Executed with no input on STDIN";
}

:endofperl
