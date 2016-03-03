package NewThread::PriorityQueue;
use parent 'NewThread::Queue';
use strict;
use warnings;

use feature 'say';

use threads::shared;
use FreezeThaw qw/ freeze thaw /;



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

	$self->max_size($args{max_size});

	return $self
}


sub queues { @_ > 1 ? $_[0]{queues} = $_[1] : $_[0]{queues} }
sub priority_levels { @_ > 1 ? $_[0]{priority_levels} = $_[1] : $_[0]{priority_levels} }
sub default_priority { @_ > 1 ? $_[0]{default_priority} = $_[1] : $_[0]{default_priority} }





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
