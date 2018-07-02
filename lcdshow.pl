#!/usr/bin/perl -w

use strict;
use IO::Socket;
use Fcntl;

my $server = "localhost";
my $port = "13666";

# wait-time (in seconds) when we are all done
my $waittime = 6;

my $remote = IO::Socket::INET->new(
                Proto     => "tcp",
                PeerAddr  => $server,
                PeerPort  => $port,
        ) or die "Cannot connect to LCDproc port ($server:$port)\n";

$remote->autoflush(1);

sleep 1;        # Give server plenty of time to notice us...

print $remote "hello\n";
my $lcdconnect = <$remote>;

my $lcdwidth = 16; 
my $lcdheight= 2;

# Turn off blocking mode...
fcntl($remote, F_SETFL, O_NONBLOCK);

# Set up some screen widgets...
my $hostname = `hostname`;
$hostname =~ s/^\s+|\s+$//g;

print $remote "client_set name {$hostname}\n";
print $remote "screen_add $hostname\n";
print $remote "screen_set $hostname name {$hostname}\n";

print $remote "widget_add $hostname title title\n";
print $remote "widget_set $hostname title {$hostname}\n";

print $remote "widget_add $hostname ident1 string\n";


# Compose the ident message(s) and calculate where to render it/them
my $ident1;

for my $i (0..9) {

        $ident1 =  `hostname -I`;
        $ident1 =~ s/^\s+|\s+$//g;

        # Display the ident message(s)
        my $cmd = sprintf("widget_set $hostname ident1 1 2 {%s}", $ident1);
        print $remote $cmd, "\n";

        sleep($waittime);

        # eat all input from LCDd
        while(defined(my $input = <$remote>)) { }

}

exit 1;
