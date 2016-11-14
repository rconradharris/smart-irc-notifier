use strict;
use File::Basename;
use File::Path 'make_path';
use vars qw($SCROLLBACK $VERSION %IRSSI);

use Irssi;
$SCROLLBACK = 25;
$VERSION = '0.0.5';
%IRSSI = (
	authors     => 'Rick Harris',
	contact     => 'rconradharris@gmail.com',
	name        => 'reply',
	description => 'Reply to IRC messages programmatically',
	url         => '<add this>',
	license     => 'GNU General Public License',
	changed     => '$Date: 2016-09-27 12:00:00 +0100 (Tue, 27 Sep 2016) $'
);

sub reply_poller {
    foreach my $path (glob(Irssi::get_irssi_dir() . "/reply-data/*")) {
        # Determine if file is recent enough
        my $age = time - basename($path);
        if ($age < 30) {
            # Read file and send IRC message to target
            open(my $file, '<', $path);
            (my $network, my $target, my $reply) = split /[:\s]+/, <$file>, 3;
            Irssi::server_find_tag($network)->command('msg ' . $target . ' ' . $reply);
            close($file);
        }
        unlink $path;
    }
}

sub append_file {
	my ($filename, $text) = @_;
    my $path = Irssi::get_irssi_dir() . "/" . $filename;
    make_path(dirname($path));
    open(my $file, ">>".$path);
    print($file $text . "\n");
    close($file);
    # Rotate file
    system("tail -n$SCROLLBACK $path > $path.tmp && mv $path.tmp $path");
}

sub handle_msg {
    my ($dest, $text, $stripped) = @_;

    # Log Transcript
    if (($dest->{level} & MSGLEVEL_PUBLIC) || ($dest->{level} & MSGLEVEL_MSGS)) {
        my $network = $dest->{server}->{tag};
        my $hilight = $dest->{level} & MSGLEVEL_HILIGHT ? '! ' : '';
        append_file("transcripts/" . $network . "/" . $dest->{target},
                    $hilight . $stripped);
    }

    # Notify
    if (($dest->{level} & MSGLEVEL_HILIGHT) || ($dest->{level} & MSGLEVEL_MSGS)) {
        my ($author) = $stripped =~ /\<\s*[@]*(\w+)\s*\>/;
        # Do not send notifications for messages that your wrote
        if ($author ne $dest->{server}->{nick}) {
            my $network = $dest->{server}->{tag};
            append_file('fnotify', $network . ' ' . $dest->{target} . ' ' . $stripped);
        }
    }
}


Irssi::signal_add_last("print text", "handle_msg");
Irssi::timeout_add(250, "reply_poller", "");
