#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use threads;
use NewThread::Queue;
use NewThread::Semaphore;
use Data::Dumper;


my $queue = NewThread::Queue->new;

my $thr = threads->create(sub {
	$queue->enqueue('asdf');
	sleep 1;
	my $val = $queue->dequeue;
	say "thread got a queued value: $val";
	sleep 2;
	$queue->enqueue({a => 'apple', b => 'bannana'});
	$queue->enqueue({ type => 'array', value => [1,5,10, NewThread::Queue->new] });
});


my $val = $queue->dequeue;
say "thread sent me a queued value: $val";
$queue->enqueue('qwerty');

sleep 2;
say 'dequeuing: ', Dumper $queue->dequeue;
say 'dequeuing: ', Dumper $queue->dequeue;

$thr->join;



my $sem = NewThread::Semaphore->new;
$sem->down;

my @threads;
push @threads, threads->create(sub {
	$sem->down;
	say "thread 1 got the semaphore!";
	sleep 1;
	$sem->up;
});
push @threads, threads->create(sub {
	$sem->down;
	say "thread 2 got the semaphore!";
	sleep 1;
	$sem->up;
});
push @threads, threads->create(sub {
	$sem->down;
	say "thread 3 got the semaphore!";
	sleep 1;
	$sem->up;
});

say "original thread holds the semaphore!";
sleep 1;
$sem->up;

$_->join for @threads;





