# Copyright: 2001-2003 The Perl Foundation.  All Rights Reserved.
# $Id$

=head1 NAME

config/auto/signal.pm - Signals

=head1 DESCRIPTION

Determines some signal stuff.

=cut

package auto::signal;

use strict;
use vars qw($description @args);

use base qw(Parrot::Configure::Step::Base);

use Parrot::Configure::Step ':auto';

$description = "Determining some signal stuff...";

@args = qw(miniparrot verbose);

sub runstep
{
    my ($self, $conf) = @_;

    my $verbose = $conf->options->get('verbose');

    $conf->data->set(
        has___sighandler_t => undef,
        has_sigatomic_t    => undef,
        has_sigaction      => undef,
        has_setitimer      => undef
    );
    if (defined $conf->options->get('miniparrot')) {
        $self->set_result('skipped');
        return $self;
    }

    cc_gen('config/auto/signal/test_1.in');
    eval { cc_build(); };
    unless ($@ || cc_run() !~ /ok/) {
        $conf->data->set(has___sighandler_t => 'define');
        print " (__sighandler_t)" if $verbose;
    }
    cc_clean();

    cc_gen('config/auto/signal/test_2.in');
    eval { cc_build(); };
    unless ($@ || cc_run() !~ /ok/) {
        $conf->data->set(has_sigaction => 'define');
        print " (sigaction)" if $verbose;
    }
    cc_clean();

    cc_gen('config/auto/signal/test_itimer.in');
    eval { cc_build(); };
    unless ($@ || cc_run() !~ /ok/) {
        $conf->data->set(
            has_setitimer    => 'define',
            has_sig_atomic_t => 'define'
        );
        print " (setitimer) " if $verbose;
    }
    cc_clean();

    # now generate signal constants
    open O, ">runtime/parrot/include/signal.pasm" or die "Cant write runtime/parrot/include/signal.pasm";
    print O <<"EOF";
# DO NOT EDIT THIS FILE.
#
# This file is generated automatically by config/auto/signal.pl
#
# Any changes made here will be lost.
#
EOF
    use Config;
    my ($i, $name);
    $i = 0;
    foreach $name (split(' ', $Config{sig_name})) {
        print O ".constant SIG$name\t$i\n" if $i;
        $i++;
    }
    close O;
    
    return $self;
}

1;
