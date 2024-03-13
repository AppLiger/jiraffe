#!/bin/sh

set -e

mix local.hex --force
mix local.rebar --force
mix deps.get
