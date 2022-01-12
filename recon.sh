#!/bin/bash

RED="e[31m"
GREEN="32"
BOLDRED="\e[1;${RED}m"
BOLDGREEN="\e[1;${GREEN}m"
ENDCOLOR="\e[0m"
SEPARATOR="##################################################################################"
BANNER="                    ,.ood888888888888boo.,
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
  echo "Usage: sudo sh recon.sh <url>" >&2
  exit 1
fi

echo ${BANNER}

if ping -c 1 -W 1 "$TARGET" > /dev/null 2> /dev/null; then
  echo "OK: Target ->> $TARGET <<-"
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

if ! [ -x "$(command -v jq)" ]; then
  echo 'Download and installation of jq.\n' >&2
  sudo apt install jq
  exit 1
fi

mkdir recon_$TARGET
cd recon_$TARGET

whois $TARGET > whois.txt
(echo "${SEPARATOR}\nCMD: whois $TARGET\n${SEPARATOR}#" && cat whois.txt) > whois1 && mv whois1 whois.txt

nslookup $TARGET > dns_nslookup.txt
(echo "${SEPARATOR}\nCMD: nslookup $TARGET\n${SEPARATOR}\n" && cat dns_nslookup.txt) > nslookup1 && mv nslookup1 dns_nslookup.txt

dig $TARGET > dns_dig.txt
(echo "${SEPARATOR}\nCMD:\ndig $TARGET\n${SEPARATOR}\n" && cat dns_dig.txt) > dig1 && mv dig1 dns_dig.txt

echo "${SEPARATOR}\nCMD:\nnslookup -query=A $TARGET\n${SEPARATOR}\n" >>dns_nslookup.txt
nslookup -query=A $TARGET >>dns_nslookup.txt

echo "${SEPARATOR}\nCMD:\ndig -a $TARGET\n${SEPARATOR}" >> dns_dig.txt
dig a $TARGET >> dns_dig.txt

echo "${SEPARATOR}\nCMD:\nnslookup -query=PTR $TARGET\n${SEPARATOR}\n" >>dns_nslookup.txt
nslookup -query=PTR $TARGET >> dns_nslookup.txt

echo "${SEPARATOR}\nCMD:\ndig -x $TARGET\n${SEPARATOR}" >> dns_dig.txt
dig -x $TARGET >> dns_dig.txt

echo "${SEPARATOR}\nCMD:\nnslookup -query=TXT $TARGET\n${SEPARATOR}\n" >> dns_nslookup.txt
nslookup -query=TXT $TARGET >> dns_nslookup.txt

echo "${SEPARATOR}\nCMD:\ndig txt $TARGET\n${SEPARATOR}" >> dns_dig.txt
dig txt $TARGET >> dns_dig.txt

echo "${SEPARATOR}\nCMD:\nnslookup -query=MX $TARGET\n${SEPARATOR}\n" >> dns_nslookup.txt
nslookup -query=MX $TARGET >> dns_nslookup.txt

echo "${SEPARATOR}\nCMD:\ndig mx $TARGET\n${SEPARATOR}" >> dns_dig.txt
dig mx $TARGET >> dns_dig.txt

curl -s https://sonar.omnisint.io/subdomains/$TARGET | jq -r '.[]' | sort -u > subdomains_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/subdomains/$TARGET | jq -r '.[]' | sort -u" && cat subdomains_sonar.txt) > sonar1 && mv sonar1 subdomains_sonar.txt

curl -s https://sonar.omnisint.io/tlds/$TARGET | jq -r '.[]' | sort -u > tlds_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/tlds/$TARGET | jq -r '.[]' | sort -u\n${SEPARATOR}\n" && cat tlds_sonar.txt) > sonar1 && mv sonar1 tlds_sonar.txt

curl -s https://sonar.omnisint.io/all/$TARGET | jq -r '.[]' | sort -u > all_tlds_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/all/$TARGET | jq -r '.[]' | sort -u\n${SEPARATOR}\n" && cat all_tlds_sonar.txt) > sonar1 && mv sonar1 all_tlds_sonar.txt

curl -s "https://crt.sh/?q=${TARGET}&output=json" | jq -r '.[] | "\(.name_value)\n\(.common_name)"' | sort -u > ${TARGET}_crt.txt
(echo "${SEPARATOR}\nCMD:curl -s \"https://crt.sh/?q=${TARGET}&output=json\" | jq -r '.[] | \"\(.name_value)\n\(.common_name)\"' | sort -u\n\n${SEPARATOR}\n" && cat ${TARGET}_crt.txt) > crt1 && mv crt1 ${TARGET}_crt.txt

echo "\nDone\nResults written in recon_$TARGET directory"
