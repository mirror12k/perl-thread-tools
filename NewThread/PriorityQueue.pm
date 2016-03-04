package NewThread::PriorityQueue;
use parent 'NewThread::Queue';
use strict;
use warnings;

use feature 'say';

use threads::shared;
use FreezeThaw qw/ freeze thaw /;


=pod

an extension of NewThread::Queue which allows assignment of a priority to an item
multiple priority levels can be defined, defaults to three levels: 'high', 'normal', 'low'
the order in which they are given will define the order of priority

dequeue will try to dequeue items with higher priority before others

a default priority can be assigned which will be applied to each item which lacks a priority


=item new(%args)

creates a new priority thread. arguments:

priority_levels => array of priority levels in order of priority (lower index == higher priority)
default_priority => the default priority assigned to each item which lacks a priority
max_size => maximum number of items in each queue, further items are rejected from being enqueue'd

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(%args);

	$self->queues(shared_clone({}));
	$self->priority_levels(shared_clone($args{priority_levels} // [qw/ high normal low /]));
	$self->default_priority($args{default_priority} // 'normal');

	for my $level (@{$self->priority_levels}) {
		$self->queues->{$level} = shared_clone([]);
	}

	return $self
}


sub queues { @_ > 1 ? $_[0]{queues} = $_[1] : $_[0]{queues} }
sub priority_levels { @_ > 1 ? $_[0]{priority_levels} = $_[1] : $_[0]{priority_levels} }
sub default_priority { @_ > 1 ? $_[0]{default_priority} = $_[1] : $_[0]{default_priority} }




=item enqueue($item)

enters an item into the queue with default priority
returns 0 if queue if queue is full and won't accept the item

=item enqueue($priority, $item)

enters an item into the queue with the given priority
returns 0 if queue if queue is full and won't accept the item

=cut
sub enqueue {
	my ($self, $item, $priority);
	($self, $item) = @_ if @_ < 3;
	($self, $priority, $item) = @_ if @_ >= 3;
	$priority //= $self->default_priority;

	my $queue_lock = $self->queue_lock;
	lock($queue_lock);
	
	return 0 if defined $self->max_size and @{$self->queues->{$priority}} >= $self->max_size;

	push @{$self->queues->{$priority}}, freeze $item;

	cond_signal $queue_lock; # signal any thread waiting for an item

	return 1
}



=item dequeue()

returns an item from the queue
it will always return the highest priority item that's available 

=cut
sub dequeue {
	my ($self) = @_;

	my $queue_lock = $self->queue_lock;
	lock($queue_lock);

	while (1) {
		for my $level (@{$self->priority_levels}) {
			if (@{$self->queues->{$level}}) {
				my ($obj) = thaw shift @{$self->queues->{$level}};
				return $obj
			}
		}
		cond_wait $queue_lock; # if the queue is empty, wait until an enqueue signals us
	}
}


=item dequeue_nb()

returns an item from the queue or undef if the queue is empty
it will always return the highest priority item that's available 

=cut
sub dequeue_nb {
	my ($self) = @_;

	my $queue_lock = $self->queue_lock;
	lock($queue_lock);

	for my $level (@{$self->priority_levels}) {
		if (@{$self->queues->{$level}}) {
			my ($obj) = thaw shift @{$self->queues->{$level}};
			return $obj
		}
	}
	return
}




1
