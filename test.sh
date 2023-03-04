FILES=$(find . -maxdepth 1)
MKDIR=""
while IFS= read -r FILENAME
do
  if [ -d "$FILENAME" ]
  then
    if [ "$FILENAME" != "." ]
    then
      MKDIR="${MKDIR}mkdir -m $(stat -f %Mp%Lp "$FILENAME") -p \"$FILENAME\";"
    fi
  fi
done<<EOF
$FILES
EOF
echo $MKDIR
