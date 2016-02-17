#!/bin/false
# ABSTRACT: An OOP interface to Monit.
# PODNAME: Monit::HTTP

use warnings;
use strict;

package Monit::HTTP;

use HTTP::Tiny;
use XML::Fast;

our (
    %MONIT_ACTIONS,
    %MONIT_ACTIONS_REV,
    %MONIT_STATUS,
    %MONIT_STATUS_REV,
    %MONIT_TYPES,
    %MONIT_TYPES_REV,
    %MONIT_MONITOR,
    %MONIT_MONITOR_REV,
);

BEGIN {

%MONIT_ACTIONS_REV = (
    'stop'      => 'ACTION_STOP',
    'start'     => 'ACTION_START',
    'restart'   => 'ACTION_RESTART',
    'monitor'   => 'ACTION_MONITOR',
    'unmonitor' => 'ACTION_UNMONITOR',
);
%MONIT_ACTIONS = reverse %MONIT_ACTIONS_REV;

%MONIT_MONITOR_REV = (
    0 => 'off',
    1 => 'monitored',
    2 => 'initializing',
);
%MONIT_MONITOR = reverse %MONIT_MONITOR_REV;

%MONIT_STATUS_REV = (
    0   => 'Running',
    32  => 'Connection Failed',
    512 => 'Does not exist',
);
%MONIT_STATUS = reverse %MONIT_STATUS_REV;

%MONIT_TYPES_REV = (
    0 => 'TYPE_FILESYSTEM',
    1 => 'TYPE_DIRECTORY',
    2 => 'TYPE_FILE',
    3 => 'TYPE_PROCESS',
    4 => 'TYPE_HOST',
    5 => 'TYPE_SYSTEM',
    6 => 'TYPE_FIFO',
    7 => 'TYPE_STATUS',
);
%MONIT_TYPES = reverse %MONIT_TYPES_REV;
}

# perl 5.10 has strange issues just going:
#   use constant reverse %{ MONIT_TYPES() }
# So work around it with do {}
use constant do { my %foo = reverse( %MONIT_TYPES_REV ); \%foo };
use constant do { my %foo = reverse( %MONIT_ACTIONS_REV ); \%foo };

use Exporter;

our %EXPORT_TAGS = (
    constants => [qw/
        ACTION_MONITOR
        ACTION_RESTART
        ACTION_START
        ACTION_STOP
        ACTION_UNMONITOR

        TYPE_DIRECTORY
        TYPE_FIFO
        TYPE_FILE
        TYPE_FILESYSTEM
        TYPE_HOST
        TYPE_PROCESS
        TYPE_SYSTEM
    /],

    hashes => [qw/
        %MONIT_ACTIONS
        %MONIT_ACTIONS_REV
        %MONIT_STATUS
        %MONIT_STATUS_REV
        %MONIT_TYPES
        %MONIT_TYPES_REV
        %MONIT_MONITOR
        %MONIT_MONITOR_REV
    /],
);

our @EXPORT_OK = (
    @{$EXPORT_TAGS{constants}},
    @{$EXPORT_TAGS{hashes}},
);

our @ISA = qw(Exporter);

=pod

=encoding utf-8

=cut

=head1 SYNOPSIS

 use Monit::HTTP;

 # Use defaults to authenticate
 my $monit = Monit::HTTP->new( use_auth => 1 );

 # Or specify what you need (defaults displayed)
 my $monit = Monit::HTTP->new(
            hostname => '127.0.0.1',
            port     => '2812',
            use_auth => 0,
            username => 'admin',
            password => 'monit',
            );

 # list processes
 my @processes = $hd->get_services();

=head1 DESCRIPTION

This module exposes an interface to talk with Monit via its HTTP interface.
You can use it to get the status of all the monitored services on that particular
host such as CPU and Memory usage, current PID, parent PID, current running status,
current monitoring status and so on.
The module can be used also for performing actions like:

=head1 COMMON USE CASES

=over

=item * Start/Stop/Restart services

Send a PR with an example!

=item * Monitor/Unmonitor services

    use Monit::HTTP ':constants';
    use Try::Tiny; # or your favourite

    my $hd = Monit::HTTP->new(
            use_auth => 1,
            );

    try {
        my @processes = $hd->get_services(TYPE_PROCESS);
        $hd->command_run($processes[0], ACTION_STOP);
        my $service_status_href = $hd->service_status($processes[0]);
    }
    catch {
        print "caught error: $_"
    };


=back

=head1 EXPORTED CONSTANTS

When brought in with:

 use Monit::HTTP ':hashes';

This module will export these variables:

=over 4

=item %MONIT_ACTIONS

Contains the following keys with corresponding codes:

 ACTION_MONITOR
 ACTION_RESTART
 ACTION_START
 ACTION_STOP
 ACTION_UNMONITOR

=item %MONIT_ACTIONS_REV

As per I<%MONIT_ACTIONS> but with keys and values reversed.

=item %MONIT_STATUS

Contains possible service status's with corresponding codes.

Probably I<%MONIT_STATUS_REV> is more useful to you.

=item %MONIT_STATUS_REV

As per I<%MONIT_STATUS> but with keys and values reversed.

Look up human readable status from its code using the status code.

=item %MONIT_TYPES

Contains the following keys with corresponding codes.

 TYPE_DIRECTORY
 TYPE_FIFO
 TYPE_FILE
 TYPE_FILESYSTEM
 TYPE_HOST
 TYPE_PROCESS
 TYPE_SYSTEM

Use this hash when requesting certain service types

=item %MONIT_TYPES_REV

As per I<%MONIT_TYPES> but with keys and values reversed.

Look up the status type from its code using this hash.

=item %MONIT_MONITOR

Contains the monitoring status's with corresponding codes.

Probably I<%MONIT_MONITOR_REV> is of more use to you.

=item %MONIT_MONITOR_REV

As per I<%MONIT_MONITOR> but with keys and values reversed.

Look up human readable monitoring status from its code using the status code.

=back

When brought in with:

 use Monit::HTTP ':constants';

This module exports a set of constants:

 TYPE_FILESYSTEM
 TYPE_DIRECTORY
 TYPE_FILE
 TYPE_PROCESS
 TYPE_HOST
 TYPE_SYSTEM
 TYPE_FIFO

 ACTION_STOP
 ACTION_START
 ACTION_RESTART
 ACTION_MONITOR
 ACTION_UNMONITOR

Use them as arguments for methods.

B<Note:> the above are all from L<constant>, so they are sub's.

=head1 METHODS

=head2 C<$monit = Monit::HTTP-E<gt>new(...)>

Constructor method, which creates a new C<Monit::HTTP> object.

This constructor can be called passing a list of various parameters:

    my $monit = Monit::HTTP->new(
                    hostname => 'localhost',
                    port     => 2812,
                    use_auth => 0,
                    username => 'admin',
                    password => 'monit'
        );

B<FYI> The values above are the default values in case no argument
is passed to the constructor.

If I<use_auth> is equal to 1 (true) and username and password are not null the http
request will be peformed using those usernames and password (basic http auth).
Be aware that if you provide username and password and you don't set
I<use_auth> to be 1 authentication won't work.

=cut

sub new {
    my ($class, %self) = @_;

    # OOP stuff
    $class = ref($class) || $class;
    my $self = \%self;
    bless $self, $class;

    # set some defaults, if not already set
    $self->{hostname} ||= 'localhost';
    $self->{port} ||= 2812;
    $self->{use_auth} ||= 0;
    if($self->{use_auth}) {
        $self->{username} ||= 'admin';
        $self->{password} ||= 'monit';
    }

    $self->{ua} = HTTP::Tiny->new( agent => sprintf('Perl %s/%s',__PACKAGE__,$Monit::HTTP::VERSION) );
    $self->_generate_url;

    return $self
}

sub _generate_url {

    my $self = shift;

    my $auth = '';
    if (defined $self->{username} and defined $self->{password} and $self->{use_auth}) {
        $auth = sprintf('%s:%s@',$self->{username},$self->{password})
    }

    $self->{status_url} = sprintf('http://%s%s:%d/_status?format=xml',
                               $auth, $self->{hostname}, $self->{port});
}

=head2 C<$monit-E<gt>set_hostname($hostname)>

Set the hostname of the monit instance

=cut

sub set_hostname {
    my ($self, $hostname) = @_;
    $self->{hostname} = $hostname;
    $self->_generate_url;
    return $hostname
}

=head2 C<$monit-E<gt>set_port($port)>

Set the tcp port of the monit instance

=cut

sub set_port {
    my ($self, $port) = @_;
    $self->{port} = $port;
    $self->_generate_url;
    return $port
}

=head2 C<$monit-E<gt>set_username($username)>

Set the username to be used in thee basic http authentication

=cut

sub set_username {
    my ($self, $username) = @_;
    $self->{username} = $username;
    $self->_generate_url;
    return $username
}

=head2 C<$monit-E<gt>set_password($password)>

Set the password to be used in thee basic http authentication

=cut

sub set_password {
    my ($self, $password ) = @_;
    $self->{password} = $password;
    $self->_generate_url;
    return $password
}

=head2 C<$res = $monit-E<gt>_fetch_info()>

Called by L</get_services>.

Does not need to be called by user. This is a private (internal) method
This private function connects via http (GET) to the monit server.

URL requested is http://<hostname>:<port>/_status?format=xml

An XML file is returned and parsed using L<XML::Fast>.

The raw XML data is stored in the object using the L</_set_xml> method.
The raw XML data can be retrieved using L</_get_xml>.

An hash reference of the XML data (as the one returned by the L<parse_xml|XML::Fast/parse_xml> function of
L<XML::Fast>) is stored in the object.

=cut

sub _fetch_info {
    my ($self) = @_;

    my $res = $self->{ua}->get( $self->{status_url} );
    if ($res->{success}) {
        $self->_set_xml($res->{content});
        $self->{xml_hash} = xml2hash( $self->_get_xml );
    }
    else {
        die sprintf "Error while connecting to %s !\n" .
            "Status: %s\nReason: %s\nContent: %s\n",
        $self->{status_url}, $res->{status}, $res->{reason}, $res->{content} || 'NIL';
    }

    return 1
}

=head2 C<$res = $monit-E<gt>get_services()>

Return an array of services configured on the remote monit daemon.

In case of any exepction an error is thrown and undef is returned.

=cut

sub get_services {
    my ($self, $type) = @_;
    my @services;
    $type ||= '-1';

    die "Don't understand this service type!\n"
        unless $type == -1 or grep {$_ == $type} keys %{MONIT_TYPES()};

    $self->_fetch_info;

    for my $s (@{$self->{xml_hash}->{monit}->{service}}) {
        if ($type == -1 or $s->{'-type'} == $type) {
            push @services,  $s->{name};
        }
    }
    return @services;
}

=head2 C<$res = $monit-E<gt>_set_xml($xml)>

Private method to set raw xml data.
Called from L</_fetch_info>

=cut

sub _set_xml {
    my ($self, $xml) = @_;
    $self->{status_raw_content} = $xml;
}

=head2 C<$res = $monit-E<gt>_get_xml($xml)>

Private method to get raw xml data.
Called from L</_fetch_info>

=cut

sub _get_xml {
    my ($self) = @_;
    return $self->{status_raw_content};
}

=head2 C<$hashref_tree = $monit-E<gt>service_status($servicename)>

Returns the status for a particular service in form of hash with all the info
for that service.
Return undef is the service does not exists.
To know the structure of the hash ref use L<Data::Dumper> :D

=cut

sub service_status {
    my ($self, $service) = @_;
    my $status_href = {};

    $self->_fetch_info;

    for my $s (@{$self->{xml_hash}->{monit}->{service}}) {
        if ($s->{name} eq $service) {

            $status_href->{host} = $self->{hostname};

            $status_href->{'type'} = $s->{'-type'}
                if exists $s->{'-type'};

            for my $thing (qw/
                    children
                    collected_sec
                    collected_usec
                    euid
                    gid
                    group
                    monitor
                    monitormode
                    pid
                    ppid
                    name
                    pendingaction
                    status
                    status_hint
                    uid
                    uptime
                    /) {

                $status_href->{$thing} = $s->{$thing}
                    if exists $s->{$thing};

            } # main stuff loop

            # the 'system' (type 5) service sticks these things in to ->{system}, others are top level
            if (my $sys = $s->{system} || $s) {
                for my $thing (qw/ kilobyte kilobytetotal percent percenttotal /) {
                    $status_href->{memory}->{$thing} = $sys->{memory}->{$thing}
                        if exists $sys->{memory}->{$thing};
                } # memory loop

                for my $thing (qw/ kilobyte percent /) {
                    $status_href->{swap}->{$thing} = $sys->{swap}->{$thing}
                        if exists $sys->{swap}->{$thing};
                } # swap loop

                for my $thing (qw/ percent percenttotal /) {
                    $status_href->{cpu}->{$thing} = $sys->{cpu}->{$thing}
                        if exists $sys->{cpu}->{$thing};
                } # cpu loop

                for my $thing (qw/ avg01 avg05 avg15 /) {
                    $status_href->{load}->{$thing} = $sys->{load}->{$thing}
                        if exists $sys->{load}->{$thing};
                } # load loop

            }
        }
    }

    die "Service $service does not exist\n"
        unless scalar keys %$status_href;

    return $status_href

}

=head2 C<$monit-E<gt>command_run($servicename, $command)>

Perform an action against a service.
$command can be a constant (ACTION_STOP, ACTION_START, ACTION_RESTART, ACTION_MONITOR, ACTION_UNMONITOR)

This method throws errors in case something goes wrong. Use eval { } statement to catch the error.

=cut

sub command_run {
    my ($self, $service, $command) = @_;

    die "Don't understand this action\n"
        unless grep { $command eq $_ } keys %{MONIT_ACTIONS()};

    if(not defined $service) {
        $self->{is_success} = 0;
        die "Service not specified\n";
    }

    # if services does not exist throw error

    my $url = 'http://'.$self->{hostname}.':'.$self->{port}.'/'.$service;

    my $res = $self->{ua}->post_form($url, { action => $command });
    die $res->{status}
        unless $res->{success};

    return 1
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-monit-http-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Monit-HTTP-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Monit::HTTP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Monit-HTTP-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Monit-HTTP-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Monit-HTTP-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Monit-HTTP-API>

=back

=head1 ACKNOWLEDGEMENTS

=cut

1; # End of Monit::HTTP
