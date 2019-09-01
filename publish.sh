#! /bin/bash
git submodule update
hugo
git co master
rm -r ./*
git co src -- public
mv public/* .
rm -r public
