#!/usr/bin/perl 

# Clipshare - share clipboard between GNOME desktops
# Copyright (C) 2010 Luke Ross <lr@lukeross.name>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

use strict;
use warnings;
use utf8;

use Data::Dumper;
use Glib;
use Gtk2 '-init';
use IO::Socket::INET;
use Storable qw(freeze thaw);

use constant DEBUG => 1;

# We'll manage these clipboards
my %clipboards = (
	primary   => Gtk2::Clipboard->get( Gtk2::Gdk->SELECTION_PRIMARY()),
	clipboard => Gtk2::Clipboard->get( Gtk2::Gdk->SELECTION_CLIPBOARD()),
);

# Set up the network connections
my $socket;
my $listen;
if (@ARGV) { # Connect to host
	$socket = IO::Socket::INET->new(PeerAddr => shift(), PeerPort => 6969, Proto => "tcp") or die $!;
} else {     # Listen for connections
	my $listen = IO::Socket::INET->new(LocalPort => 6969, Listen => 1, Proto => "tcp") or die $!;
	$socket = $listen->accept() or die $!;
}

# Set up a select mask 
my $rin = "";
vec($rin,$socket->fileno(),1) = 1;

# Get notification of clipboard changes
$_->signal_connect(owner_change => \&owner_change) foreach values %clipboards;

# Try to shut down cleanly
$SIG{INT}     = \&clean_up;
$SIG{__DIE__} = \&clean_up;

# Set up the message polling handler
Glib::Timeout->add(100, \&handler);

# And go
Gtk2->main();

my %owner_is_me; # Whether I own the clipboard and need to ignore changes
my %targets;     # What formats the remote clipboard supports

# Owder changed
sub owner_change {
	my ($clip, $event) = @_;
	my $name = (grep { $clip == $clipboards{$_} } keys %clipboards)[0]; # Which clipboard changed?
	print STDERR "owner_change($name): $owner_is_me{$name}\n" if DEBUG;
	return if $owner_is_me{$name}-- > 0; # Am I ignoring change events?
	$owner_is_me{$name} = 0 if $owner_is_me{$name} < 0; # Cannot fall below zero
	print STDERR "Selection of $name changed, sending notification.\n" if DEBUG;
	my @targets = $clip->wait_for_targets(); # Request the formats this new clipboard supports
	# Now send the notification and format list to the other side
	my $payload = pack("cZ*a*", ord("C"), $name, freeze([ map { $_->name } @targets ]));
	$socket->print(pack("N", length($payload)) . $payload);
}

sub handler {
	# Regular poll of the socket for new messages
	eval {
		while (select(my $dummy = $rin, undef, undef, 0.1)) {
			handle_message();
		}
	};
	if ($@) {
		print "Error: $@, quitting\n";
		Gtk2->main_quit();
		clean_up(); # Attempt to close sockets
		return 0;
	}
	return 1;
}

my $disabled = 0;

sub handle_message {
	print STDERR "handle_message: @_\n" if DEBUG;
	return 1 if $disabled and not @_; # Someone's waiting for data, don't slurp it here
	# Read the packet length
	$socket->read(my $length, 4) or die $!;
	$length = unpack("N", $length);
	# Read the packet ($length characters)
	my $buffer = "";
	while(length $buffer < $length) {
		$socket->read($buffer, $length - length($buffer));
	}
	# Unpack it into packet format, the affected clipboard and the payload
	my ($msg, $clip, $data) = unpack("cZ*a*", $buffer);
	$msg = chr($msg);
	if ($msg eq "C") {
		# Other clipboard changed, grab the local clipboard to match
		print STDERR "Remote selection $clip changed, updating local clipboard.\n" if DEBUG;
		print STDERR "formats = ". join(",", @{ thaw($data) }) . "\n" if DEBUG;
		$targets{$clip} = thaw($data);
		my $counter = 0;
		$owner_is_me{$clip}++;
		if (@{ $targets{$clip} }) {
			$clipboards{$clip}->set_with_data(\&fetch_remote_data, \&become_inactive, $clip, map {[ $_, [], $counter++ ]} @{ $targets{$clip} });
		} else {
			$clipboards{$clip}->clear();
		}
	}
	if ($msg eq "R") {
		# Other side requested data, return it to them
		my $target_format = ${ thaw($data) };
		print STDERR "Remote requested contents of selection $clip, sending in format $target_format.\n" if DEBUG;
		my $content = @_ ? undef : $clipboards{$clip}->wait_for_contents(Gtk2::Gdk::Atom->new($target_format)); # Stuck in a loop?
		$content = $content ? {
			data_type => $content->get_data_type()->name(),
			data      => $content->get_data(),
			format    => $content->get_format()
		} : {}; # Urgh, nothing
#		print STDERR Dumper $content if DEBUG;
		# And send
		my $payload = pack("cZ*a*", ord("D"), $clip, freeze($content));;
		$socket->print(pack("N", length($payload)) . $payload);
	}
	if ($msg eq "D") {
		# Other side sent data in response to our request
		print STDERR "Remote returned contents of selection $clip.\n" if DEBUG;
		return thaw($data);
	}
	return 1; # Reschedule the polling
}

# A local app asked for the data from the remote clipboard
sub fetch_remote_data {
	my ($clipobj, $selectiondata, $id, $clip) = @_;
	print STDERR "Local app requested remote selection, fetching data from remote.\n" if DEBUG;
	print STDERR "Asking remote for format in id=$id, format=" . $targets{$clip}[$id] . "\n" if DEBUG;
	# What format do I want it in?
	my $content = $targets{$clip}[$id];
	# Request it
	my $payload = pack("cZ*a*", ord("R"), $clip, freeze(\$content));;
	$socket->print(pack("N", length($payload)) . $payload);
	my $return;
	$disabled = 1; # Disable polling
	while(not ref $return) { # Keep handling messages til I get a response
		$return = handle_message(1);
	}
	$disabled = 0; # Enable polling again
	# Return the data to the local app
	$selectiondata->set(Gtk2::Gdk::Atom->new($return->{data_type}), $return->{format}, $return->{data})
		if $return->{data_type};
}

# Another application grabbed the local clopboard. We can ignore this.
sub become_inactive {
	my ($clip_obj, $clip_name) = @_;
	print STDERR "Remote-provided selection replaced by local.\n" if DEBUG;
}

clean_up(); # Try to clean up

sub clean_up {
	eval { $socket->close() }; # Close connection to remove host
	warn $@ if $@;
	eval { $listen->close() } if $listen; # Clean up listen queue
	warn $@ if $@;
}
