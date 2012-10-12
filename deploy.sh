#! /bin/sh
git push source source:master
rake generate
rake push
rake rsync