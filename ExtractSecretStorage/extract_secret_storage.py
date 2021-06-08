#!/usr/bin/env python

import secretstorage

connection = secretstorage.dbus_init()
collection = secretstorage.get_default_collection(connection)

for item in collection.get_all_items():
	print(repr([item.get_label(), item.get_secret(), item.get_attributes()]))

