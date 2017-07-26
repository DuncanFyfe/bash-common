#!/bin/sh

# This pause is needed otherwise the init scripts are run before the DB is ready.
sleep ${PG_PAUSE}
