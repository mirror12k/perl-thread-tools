package NewThread::Semaphore;
use strict;
use warnings;

use feature 'say';

use threads::shared;


=pod

a thread-safe semaphore for more sophisticated work than simple locking

a reimplementation of Thread::Semaphore


=item new

creates a new semaphore

takes an optional argument to become its semaphore count, defaults to 1

=cut
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


=item up

increments the semaphore count. if any threads were blocking on a down, one of blocked threads will be unblocked and receive the semaphore

=cut
sub up {
	my ($self) = @_;

	my $semaphore_lock = $self->semaphore_lock;
	lock($semaphore_lock);

	$self->count($self->count + 1);

	cond_signal $semaphore_lock;
}

=item down

decrements the semaphore count. if the count would fall below 0, this call will block until another thread calls up on this semaphore

=cut
sub down {
	my ($self) = @_;

	my $semaphore_lock = $self->semaphore_lock;
	lock($semaphore_lock);

	cond_wait $semaphore_lock unless $self->count > 0;

	$self->count($self->count - 1);
}

=item down_force

unconditionally decrements the semaphore count, even if it would fall below 0

=cut
sub down_force {
	my ($self) = @_;

	my $semaphore_lock = $self->semaphore_lock;
	lock($semaphore_lock);

	$self->count($self->count - 1);
}

=item down_nb

decrements the semaphore count only if it is above 0. returns 1 when successfully decremented, 0 otherwise

=cut
sub down_nb {
	my ($self) = @_;

	my $semaphore_lock = $self->semaphore_lock;
	lock($semaphore_lock);

	return 0 unless $self->count > 0;

	$self->count($self->count - 1);
	return 1
}

1
