#! /bin/bash
git submodule update
hugo
git add . && git cm -m 'gen site'
git co master
git co . && git clean -fdx
rm -r ./*
git co src -- public
mv public/* .
rm -r public
