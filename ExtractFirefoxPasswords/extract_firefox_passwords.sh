#!/bin/sh

jq -r -S '.logins[] | .hostname, .encryptedUsername, .encryptedPassword' $1/logins.json | pwdecrypt -d $1 -p "$2"
