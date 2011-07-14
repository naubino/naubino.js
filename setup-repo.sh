#!/bin/bash
git submodule update --init lib/my-common/
git submodule sync
mkdir javascripts
coffee -o javascripts/ -cb coffee/*.coffee
