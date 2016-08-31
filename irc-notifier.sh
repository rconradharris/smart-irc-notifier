#!/bin/bash
# http://andy.delcambre.com/2008/12/06/growl-notifications-with-irssi.html
IRC_HOST=irc
NOTIFIER=/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier

[ -e $NOTIFIER ] || exit 1

# Kill any existly irc-notifier.sh commands
ps -eaf | grep bash.*irc-notifier | grep -v grep | grep -v $$ | awk '{ print $2 }' | xargs kill

# Shell into machine and start reading file
ssh irc -o PermitLocalCommand=no "ps -eaf | grep fnotify | grep -v grep | awk '{ print \$2 }' | xargs kill 2> /dev/null"

# Emit terminal-notifier notifications anytime a new line is added to
# fnotifier file
(ssh $IRC_HOST -o PermitLocalCommand=no  \
     "tail -n0 -f .irssi/fnotify " | \
   while read message; do                    \
     echo $message | $NOTIFIER -group IRC -title IRC 2>&1 > /dev/null; \
   done)&

# Update remote server with our current idle time
(while true; do
    echo $(get-idle-time)
    sleep 1
done | ssh $IRC_HOST -o PermitLocalCommand=no 'while read msg; do echo $msg > .irssi/idle-time; done;')&
