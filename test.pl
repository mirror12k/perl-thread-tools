#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use threads;
use NewThread::Queue;


my $queue = NewThread::Queue->new;

my $thr = threads->create(sub {
	$queue->enqueue('asdf');
	sleep 1;
	my $val = $queue->dequeue;
	say "thread got a queued value: $val";
	sleep 2;
	$queue->enqueue(5);
	$queue->enqueue(4);
}, 'argument');


my $val = $queue->dequeue;
say "thread sent me a queued value: $val";
$queue->enqueue('qwerty');

sleep 2;
say 'dequeuing:', $queue->dequeue;
say 'dequeuing:', $queue->dequeue;

$thr->join;

