#!/usr/bin/env dash
#TTY=$(echo /dev/$(ps -p $$ -o tty=))
#cat test.sh | ssh -i ~/.ssh/dino_ed25519 -tt ec2-user@jonrad8571 'bash -i' < /dev/ttys000 &
#stty raw -echo
#fg
#reset

input="item1 item2 item3"

setopt shwordsplit 2>/dev/null

for item in $input
do
  tty -s && echo yes  || echo no >&2
  echo $item
done

unsetopt shwordsplit 2>/dev/null
