package NewThread::Pipe;
use strict;
use warnings;

use threads::shared;


=pod

an implementation of a socket-like interface between two threads
create a pipe before starting another thread to begin use

communication is bi-directional
currently only read and print are supported

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {}, $class;

	my $selector = 0;
	$self->value_selector(shared_clone(\$selector));
	my $value0 = '';
	$self->value0(shared_clone(\$value0));
	my $value1 = '';
	$self->value1(shared_clone(\$value1));

	return $self
}


sub value0 { @_ > 1 ? $_[0]{value0} = $_[1] : $_[0]{value0} }
sub value1 { @_ > 1 ? $_[0]{value1} = $_[1] : $_[0]{value1} }
sub value_selector { @_ > 1 ? $_[0]{value_selector} = $_[1] : $_[0]{value_selector} }

sub selected { @_ > 1 ? $_[0]{selected} = $_[1] : $_[0]{selected} }

sub value_select {
	my ($self) = @_;

	my $value_selector = $self->value_selector;
	lock ($value_selector);

	$self->selected($$value_selector);
	$$value_selector++
}


sub my_value {
	my ($self) = @_;
	$self->value_select unless defined $self->selected;
	if ($self->selected == 0) {
		return $self->value0
	} else {
		return $self->value1
	}
}

sub peer_value {
	my ($self) = @_;
	$self->value_select unless defined $self->selected;
	if ($self->selected == 0) {
		return $self->value1
	} else {
		return $self->value0
	}
}



sub read {
	my ($self, $length) = @_;

	my $value = $self->my_value;
	lock($value);

	return unless length $$value;

	my $buffer;
	if ($length <= length $$value) {
		$buffer = substr $$value, 0, $length;
		$$value = substr $$value, $length;
	} else {
		$buffer = substr $$value, 0, length $$value;
		$$value = '';
	}
	return $buffer
}

sub print {
	my $self = shift;

	my $value = $self->peer_value;
	lock($value);

	$$value .= join '', @_;
}

1
