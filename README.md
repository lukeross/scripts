ClipShare
=========

ClipShare allows you to share clipboards between two computers with GTK
installed. Requires a recent version of perl, perl-Gtk and perl-Glib.

ClipShare can send more than just text - you can copy and paste pictures
and most other complex data formats. 

Usage
-----

On the server (must expose TCP port 6969):

    ./clipshare

On the client:

    ./clipshare <server hostname>

Date is transferred unencrypted, so the use of eg. an SSH tunnel is
recommended for transfer across public networks.
