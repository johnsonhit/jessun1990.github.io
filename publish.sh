#! /bin/bash
git submodule update
hugo
git add . && git cm -m 'gen site'
git co master
#rm -r ./*
#git co src -- public
#mv public/* .
#rm -r public
