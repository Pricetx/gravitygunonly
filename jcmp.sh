#!/bin/sh
#-
#
# Copyright (c) 2013 Jonathan Price <jonathan@jonathanprice.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

# jcmp.sh
#
# Server managing script for JC-MP servers, using tmux. Includes commands
# to start, stop and restart the server, as well as being able to update the
# server, and access the server console.
#
# Comments, suggestions, bug reports please to:
# Jonathan Price <jonathan@jonathanprice.org>
#
# NOTE: REQUIRES TMUX TO BE INSTALLED

# The AppID of the game you're using. A list can be found here:
# https://developer.valvesoftware.com/wiki/Steam_Application_IDs
APPID="261140"

# location of the game folder
DIR="/home/jcmp/jcmp/"

# The location of your SteamCMD binary
UPDATEDIR="/home/jcmp/steamcmd/"

# The name given to the tmux session
NAME="jc2mp"



# STARTUP PARAMETERS
# DO NOT EDIT THIS SECTION



# Determines whether there is a tmux server running
TMUXPID=$(pgrep -u "$(whoami)" -f "tmux" )

# The name of the main binary
BIN="Jcmp-Server"

# Prints the game and tmux session
INFO="Game: $BIN | tmux session: $NAME"

# The name of the main SteamCMD script file
UPDATEBIN="steamcmd.sh"

# Server update arguments
UPDATEARGS="+login anonymous +force_install_dir $DIR +app_update $APPID validate +quit"

# Is "stopping" or "restarting" based on command given
STATUS=""



# FUNCTIONS
# DO NOT EDIT THIS SECTION



# Starts the server, performing the following pre-startup checks:
# is tmux installed
# Does a tmux session with the same name already exist
# does the game folder $DIR exist
# has an $RDTSC value been given
doStart() {
        if [ ! "$(command -v tmux)" ]; then
                echo "ERROR: tmux could not be found, is it installed?"
                exit 1
        fi

        if [ "$TMUXPID" ]; then
                if [ -n "$(tmux list-sessions | grep $NAME)" ]; then
                        echo "ERROR: A tmux session with the name $NAME already exists"
                        exit 1
                fi
        fi

        if [ ! -d $DIR ]; then
                echo "ERROR: Could not find $DIR. Is the path correct?"
                exit 1
        fi

                echo "Starting server"
                cd $DIR
                tmux new-session -d -s $NAME "./$BIN $ARGS"
                tmux attach-session -t $NAME
}


# Stops the server, performing the following checks first
# Checks if tmux is running
# Checks if a tmux session with the correct name exists
doStop() {
    if [ ! "$TMUXPID" ]; then
                echo "ERROR: tmux is not running"
                exit 1
    fi

        if [ ! -n "$(tmux list-sessions | grep $NAME)" ]; then
                echo "ERROR: A tmux session with the name $NAME couldn't be found"
                exit 1
        fi

        echo "Giving 10 second countdown warning."

        for i in 10 9 8 7 6 5 4 3 2 1; do
                printf "%s " "$i"
                tmux send-keys -t $NAME "say The server is $STATUS in $i seconds." ENTER
                sleep 1
        done
        echo "Stopping Server"
        tmux send-keys -t $NAME "quit" ENTER

        while [ -n "$(tmux list-sessions | grep $NAME)" ]; do
                sleep 1
        done
}

# Restarts the server. For checks, see stop and start functions.
doRestart() {
        doStop
        doStart
}

# Updates the server. Before doing so, it runs the following checks:
# Checks for the existance of the SteamCMD folder $UPDATEDIR
# Checks for the existance of the SteamCMD script $UPDATEBIN
# Checks to see if the server is running. If so, stop the server,
# and start it again aftwards.
doUpdate() {
        local wasRunning="false"

        if [ ! -d $UPDATEDIR ]; then
                echo "ERROR: $UPDATEDIR doesn't exist. Is it the correct path?"
                exit 1
        fi

        if [ -e $UPDATEBIN ]; then
                echo "ERROR: $UPDATEBIN doesn't exist. Is the path correct?"
                exit 1
        fi

        if [ -n "$(tmux list-sessions | grep $NAME)" ]; then
                echo "$NAME is currently running. Stopping before updating."
                wasRunning="true"
                doStop
        fi

        echo "Updating server"
        tmux new-session -s $NAME "$UPDATEDIR/$UPDATEBIN $UPDATEARGS"
        while [ -n "$(tmux list-sessions | grep $NAME)" ]; do
                sleep 1
        done
        if [ $wasRunning = "true" ]; then
                doStart
        fi
}

# Attaches the user's shell into the tmux session.
doConsole() {
        tmux attach-session -t $NAME
}

# Returns some basic information about the server
doStatus() {
        echo "$INFO"
        if [ -n "$(tmux list-sessions | grep $NAME)" ]; then
                echo "Status: running"
        else
                echo "Status: not running"
        fi
}



# COMMAND INTEPRETER
# DO NOT EDIT THIS SECTION



case $1 in
        start)
                doStart
        ;;
        stop)
                STATUS="stopping"
                doStop
        ;;
        restart)
                STATUS="restarting"
                doRestart
        ;;
        update)
                doUpdate
        ;;
        console)
                doConsole
        ;;
        status)
                doStatus
        ;;
        *)
                printf "%s" "Usage: $0 {start|stop|restart|update|console|status}\n"
                exit 2
        ;;
esac
