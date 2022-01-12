#!/bin/bash

RED="e[31m"
GREEN="32"
BOLDRED="\e[1;${RED}m"
BOLDGREEN="\e[1;${GREEN}m"
ENDCOLOR="\e[0m"

echo -e "                    ,.ood888888888888boo.,
              .od888P^\"\"            \"\"^Y888bo.
          .od8P''   ..oood88888888booo.    \`\`Y8bo.
       .odP'\"  .ood8888888888888888888888boo.  \"\`Ybo.
     .d8'   od8'd888888888f\`8888't888888888b\`8bo   \`Yb.
    d8'  od8^   8888888888[  \`'  ]8888888888   ^8bo  \`8b
  .8P  d88'     8888888888P      Y8888888888     \`88b  Y8.
 d8' .d8'       \`Y88888888'      \`88888888P'       \`8b. \`8b
.8P .88P            \"\"\"\"            \"\"\"\"            Y88. Y8.
88  888                                              888  88
88  888                                              888  88
88  888.        ..                        ..        .888  88
\`8b \`88b,     d8888b.od8bo.      .od8bo.d8888b     ,d88' d8'
 Y8. \`Y88.    8888888888888b    d8888888888888    .88P' .8P
  \`8b  Y88b.  \`88888888888888  88888888888888'  .d88P  d8'
    Y8.  ^Y88bod8888888888888..8888888888888bod88P^  .8P
     \`Y8.   ^Y888888888888888LS888888888888888P^   .8P'
       \`^Yb.,  \`^^Y8888888888888888888888P^^'  ,.dP^'
          \`^Y8b..   \`\`^^^Y88888888P^^^'    ..d8P^'
              \`^Y888bo.,            ,.od888P^'
                   \"\`^^Y888888888888P^^'\"\n"
TARGET=$1

if [ "$#" -ne 1 ]; then
  echo "Usage: sh recon.sh <url>" >&2
  exit 1
fi

if ping -c 1 -W 1 "$TARGET" > /dev/null 2> /dev/null; then
  echo "OK: Target $TARGET can be reach"
else
    echo "Target $TARGET doesn't seems to be reachable"
    exit 1
fi

if [ -d "recon_$TARGET" ]; then
  echo -n "\nWarning: the target $TARGET already exist ...\nWould you want to relaunch the recon script and overwrite (y/n)?\n"
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
  if echo "$answer" | grep -iq "^y" ;then
      rm -rf recon_$TARGET
  else
      echo "\nExit"
      exit 1
  fi

fi

mkdir recon_$TARGET
cd recon_$TARGET
mkdir passive_gathering
cd passive_gathering

whois $TARGET > whois.txt
(echo "CMD: whois $TARGET\n#####################" && cat whois.txt) > whois1 && mv whois1 whois.txt
nslookup $TARGET > nslookup_A_records.txt
(echo "CMD: nslookup $TARGET\n#####################" && cat nslookup_A_records.txt) > nslookup1 && mv nslookup1 nslookup_A_records.txt

dig $TARGET > dig.txt
(echo "#####################\nCMD:\ndig $TARGET\n#####################\n" && cat dig.txt) > dig1 && mv dig1 dig.txt
echo "######################\nCMD:\ndig -query=A $TARGET\n#####################" >> dig.txt
dig -query=A $TARGET >> dig.txt
echo "\nDone\nResults written in recon_$TARGET directory\n"
