#!perl

use strict;
use warnings;
use Test::More tests => 1;

use Monit::HTTP ':constants';

diag('Test the tricky export of constants is working');
is( ACTION_MONITOR, 'monitor', 'ACTION_MONITOR exported correctly' );


