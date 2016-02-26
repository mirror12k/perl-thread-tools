package NewThread::Queue;
use strict;
use warnings;

use feature 'say';

use threads::shared;
use FreezeThaw qw/ freeze thaw /;

=pod

a thread-safe queue for passing complex data between threads

a reimplementation of Thread::Queue

=item new

creates a new shared thread queue
arguments:

max_size => if defined, marks a maximum number of items in the queue

=cut
sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {}, $class;
	$self = shared_clone($self);

	$self->queue_lock(shared_clone({}));
	$self->queue(shared_clone([]));

	$self->max_size($args{max_size});

	return $self
}


sub queue_lock { @_ > 1 ? $_[0]{queue_lock} = $_[1] : $_[0]{queue_lock} }
sub queue { @_ > 1 ? $_[0]{queue} = $_[1] : $_[0]{queue} }
sub max_size { @_ > 1 ? $_[0]{max_size} = $_[1] : $_[0]{max_size} }


=item enqueue

adds one item to the queue. if a max_size is defined, it will return 1 on successful enqueue and 0 when it would overflow the max size

=cut
sub enqueue {
	my ($self, $item) = @_;

	my $queue_lock = $self->queue_lock;
	lock($queue_lock);
	
	return 0 if defined $self->max_size and @{$self->queue} + 1 > $self->max_size;

	push @{$self->queue}, freeze $item;

	cond_signal $queue_lock; # signal any thread waiting for an item

	return 1
}

=item dequeue

returns one item from the queue. if the queue is empty, it will block until an item is available

=cut
sub dequeue {
	my ($self) = @_;

	my $queue_lock = $self->queue_lock;
	lock($queue_lock);

	cond_wait $queue_lock until @{$self->queue}; # if the queue is empty, wait until an enqueue signals us

	my ($obj) = thaw shift @{$self->queue};
	return $obj
}

=item dequeue_nb

a non-blocking version of dequeue which returns undef if the queue is empty

=cut
sub dequeue_nb {
	my ($self) = @_;

	my $obj = shift @{$self->queue};
	($obj) = thaw $obj if defined $obj;

	return $obj
}


1
