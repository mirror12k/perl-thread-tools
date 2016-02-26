package NewThread::Semaphore;
use strict;
use warnings;

use feature 'say';

use threads::shared;


# a reimplementation of Thread::Semaphore


sub new {
	my ($class, $count) = @_;
	my $self = bless {}, $class;
	$self = shared_clone($self);

	$self->semaphore_lock(shared_clone({}));
	$self->count($count // 1);

	return $self
}

sub count { @_ > 1 ? $_[0]{count} = $_[1] : $_[0]{count} }
sub semaphore_lock { @_ > 1 ? $_[0]{semaphore_lock} = $_[1] : $_[0]{semaphore_lock} }

sub up {
	my ($self) = @_;

	my $semaphore_lock = $self->semaphore_lock;
	lock($semaphore_lock);

	$self->count($self->count + 1);

	cond_signal $semaphore_lock;
}

sub down {
	my ($self) = @_;

	my $semaphore_lock = $self->semaphore_lock;
	lock($semaphore_lock);

	cond_wait $semaphore_lock unless $self->count > 0;

	$self->count($self->count - 1);
}

sub down_force {
	my ($self) = @_;

	my $semaphore_lock = $self->semaphore_lock;
	lock($semaphore_lock);

	$self->count($self->count - 1);
}

sub down_nb {
	my ($self) = @_;

	my $semaphore_lock = $self->semaphore_lock;
	lock($semaphore_lock);

	return 0 unless $self->count > 0;

	$self->count($self->count - 1);
	return 1
}

1
