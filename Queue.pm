package NewThread::Queue;
use strict;
use warnings;

use feature 'say';
use threads::shared;


# a reimplementation of Thread::Queue

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {}, $class;
	$self = shared_clone($self);

	$self->queue_lock(shared_clone({}));
	$self->queue(shared_clone([]));

	return $self
}


sub queue_lock { @_ > 1 ? $_[0]{queue_lock} = $_[1] : $_[0]{queue_lock} }
sub queue { @_ > 1 ? $_[0]{queue} = $_[1] : $_[0]{queue} }

sub enqueue {
	my $self = shift;

	my $queue_lock = $self->queue_lock;
	lock($queue_lock);
	
	push @{$self->queue}, @_;
}


sub dequeue {
	my ($self) = @_;

	my $queue_lock = $self->queue_lock;
	lock($queue_lock);

	shift @{$self->queue};
}

