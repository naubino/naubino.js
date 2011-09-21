#!/bin/bash
git submodule update --init lib/my-common/
git submodule sync
mkdir js
coffee -o js/ -cb coffee/*.coffee
