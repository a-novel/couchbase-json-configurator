#!/bin/sh

BashFiles="$HOME/.bash_profile $HOME/.zshrc"

for File in $BashFiles; do
  grep -v "^PATH" "$File" >tmp.txt && mv tmp.txt "$File"
  grep -v "^export PATH=\"~/bin" "$File" >tmp.txt && mv tmp.txt "$File"
  grep -v "^alias ='sh ~/bin//'" "$File" >tmp.txt && mv tmp.txt "$File"
  grep -v "^alias ='sh ~/bin//setup-couchbase.sh'" "$File" >tmp.txt && mv tmp.txt "$File"

  grep -v "^alias couchbase-jc" "$File" >tmp.txt && mv tmp.txt "$File"
done

rm -rf ~/bin/"couchbase-jc"