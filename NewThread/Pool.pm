package NewThread::Pool;
use strict;
use warnings;

use feature 'say';

use threads;
use threads::shared;

use NewThread::Queue;

# a reimplementation of Thread::Pool

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {}, $class;
	# $self = shared_clone($self);

	$self->{jobid} = 0;

	$self->job_queue(NewThread::Queue->new(max_size => $args{job_queue_limit} // 100));
	$self->result_queue(NewThread::Queue->new(max_size => $args{result_queue_limit} // 100));
	$self->worker_threads([]);
	$self->workers($args{workers} // 10);

	$self->pre_sub($args{pre_sub});
	$self->do_sub($args{do_sub} // die "do sub required");
	$self->post_sub($args{post_sub});

	$self->start_worker for 1 .. $self->workers;

	return $self
}

sub pre_sub { @_ > 1 ? $_[0]{pre_sub} = $_[1] : $_[0]{pre_sub} }
sub do_sub { @_ > 1 ? $_[0]{do_sub} = $_[1] : $_[0]{do_sub} }
sub post_sub { @_ > 1 ? $_[0]{post_sub} = $_[1] : $_[0]{post_sub} }

sub workers { @_ > 1 ? $_[0]{workers} = $_[1] : $_[0]{workers} }
sub worker_threads { @_ > 1 ? $_[0]{worker_threads} = $_[1] : $_[0]{worker_threads} }
sub job_queue { @_ > 1 ? $_[0]{job_queue} = $_[1] : $_[0]{job_queue} }
sub result_queue { @_ > 1 ? $_[0]{result_queue} = $_[1] : $_[0]{result_queue} }

sub new_jobid { $_[0]{jobid}++ }

sub start_worker {
	my ($self) = @_;
	push @{$self->worker_threads}, threads->create(\&run_pool_thread, $self);
}

sub stop_worker {
	my ($self) = @_;
	$self->job_queue->enqueue({ type => 'stop' });
}


sub result {
	my ($self) = @_;
	return $self->result_queue->dequeue;
}


sub job {
	my $self = shift;
	my @args = @_;
	my $jobid = $self->new_jobid;
	return unless $self->job_queue->enqueue({ type => 'job', jobid => $jobid, args => \@args });
	return $jobid
}

sub join {
	my ($self) = @_;
	$self->stop_worker for 1 .. $self->workers;
	$_->join for @{$self->worker_threads};
}





sub run_pool_thread {
	my ($self) = @_;

	$self->init_pool_thread;
	$self->pool_thread_read_loop;
	$self->finalize_pool_thread;
}

sub init_pool_thread {
	my ($self) = @_;
	if (defined $self->pre_sub) {
		eval { $self->pre_sub->() };
		if ($@) {
			warn "pre-sub died: $@";
		}
	}
}

sub pool_thread_read_loop {
	my ($self) = @_;

	my $running = 1;
	while ($running) {
		my $job = $self->job_queue->dequeue;
		if ($job->{type} eq 'stop') {
			$running = 0;
		} elsif ($job->{type} eq 'job') {
			my ($ret, $error);
			$ret = eval { $self->do_sub->(@{$job->{args}}) };
			$error = $@ if $@;
			$self->result_queue->enqueue({
				jobid => $job->{jobid},
				error => $error,
				ret => $ret,
			});
		}
	}
}

sub finalize_pool_thread {
	my ($self) = @_;
	if (defined $self->post_sub) {
		eval { $self->post_sub->() };
		if ($@) {
			warn "post-sub died: $@";
		}
	}
}

1

