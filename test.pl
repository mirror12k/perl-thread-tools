#!/usr/bin/env perl
use strict;
use warnings;

use feature 'say';

use threads;
use Data::Dumper;

use NewThread::Queue;
use NewThread::Semaphore;
use NewThread::Pool;
use NewThread::Pipe;
use NewThread::PriorityQueue;




say '';
say "queue testing:";

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

say '';
say "semaphore testing:";


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





say '';
say "thread pool testing:";



my $pool = NewThread::Pool->new(
	do_sub => sub {
		my ($count) = @_;

		say "i am thread $count!";
		sleep 1;
		say "thread $count is exiting!";

		my $res = 1;
		$res *= $count for 1 .. $count;
		return $res
	}
);

$pool->job($_) for 1 .. 10;

for (1 .. 10) {
	my $res = $pool->result;
	say "got result: $res->{ret}";
}

$pool->join;


say '';
say "thread pipe testing:";

my $pipe = NewThread::Pipe->new;

my $thread = threads->create(sub {
	my $data = $pipe->read(12);
	say "child thread got data from pipe: $data";
	$pipe->print('lots and lots and lots of data' x 5);

	sleep 2;
	my $n;
	$n = unpack 'N', $pipe->read(4);
	say "child got number: $n";
	$n = unpack 'N', $pipe->read(4);
	say "child got number: $n";
	$n = unpack 'N', $pipe->read(4);
	say "child got number: $n";
	say "child thread is done!";
});
$pipe->print('hello world!');
sleep 1;
my $data = $pipe->read(4096);
say "parent thread got data from pipe: $data";

$pipe->print(pack 'NNN', 15, 25, 350);

$thread->join;



say '';
say "priority queue testing:";

$queue = NewThread::PriorityQueue->new;

$thread = threads->create(sub {
	sleep 1;
	my $item = $queue->dequeue;
	say "child thread got item: $item";
	$item = $queue->dequeue;
	say "child thread got item: $item";
	$item = $queue->dequeue;
	say "child thread got item: $item";
	$item = $queue->dequeue;
	say "child thread got item: $item";
});

$queue->enqueue('default priority item!');
$queue->enqueue(low => 'low priority item!');
$queue->enqueue(high => 'high priority item!');
$queue->enqueue(normal => 'normal priority item!');


$thread->join;
