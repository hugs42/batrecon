#!/bin/bash

RED="e[31m"
GREEN="32"
BOLDRED="\e[1;${RED}m"
BOLDGREEN="\e[1;${GREEN}m"
ENDCOLOR="\e[0m"
SEPARATOR="#########################################################################"
TARGET=$1
MODE = 1;

if [ "$#" -ne 1 ]; then
  echo "Usage: sudo sh recon.sh <url>" >&2
  exit 1
fi

echo "\n                     ,.ood888888888888boo.,
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

if ping -c 1 -W 1 "$TARGET" > /dev/null 2> /dev/null; then
  echo "OK: Target ->> $TARGET <<-"
else
    echo "Target $TARGET doesn't seems to be reachable"
    exit 1
fi

if [ -d "batrecon_${TARGET}" ]; then
  echo -n "\Would you like to perform a full recon against ${TARGET} ?\n"  echo "   - 1: Perform a full recon (both passive and active)"
  echo "   - 2: Perform only passive recon"
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
  if echo "$answer" | grep -iq "^1" ;then
      ${MODE}=1
  else
      ${MODE}=2
  fi
fi
if [ -d "batrecon_$TARGET" ]; then
  echo -n "\nWarning: the target $TARGET already exist ...\nWould you want to relaunch the recon script and overwrite (y/N)?\n"
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
  if echo "$answer" | grep -iq "^y" ;then
      rm -rf batrecon_$TARGET
  else
      echo "\nExit"
      exit 1
  fi
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Download and installation of jq\n' >&2
  sudo apt install jq > /dev/null
fi

if ! [ -x "$(command -v theHarvester)" ]; then
  echo 'Download and installation of theHarvester.\n' >&2
  git clone https://github.com/laramies/theHarvester > /dev/null
  cd theHarvester
  python3 -m pip install -r requirements/base.txt > /dev/null
  cd ..
fi

if ! [ -x "$(command -v aquatone)" ]; then
  echo 'Download and installation of aquatone\n' >&2
  sudo apt install golang chromium-driver -y > /dev/null
  go install github.com/michenriksen/aquatone@latest > /dev/null
  export PATH="$PATH":"$HOME/go/bin"
fi

if ! [ -x "$(command -v waybackurls)" ]; then
  echo 'Download and installation of waybackurls\n' >&2
  go install github.com/tomnomnom/waybackurls@latest > /dev/null
fi

mkdir batrecon_$TARGET
cd batrecon_$TARGET
mkdir passive_information_gathering
mkdir active_information_gathering
cd passive_information_gathering

echo "## Starting passive information gathering ##\n"

echo ">> Running whois lookup ... "
mkdir whois
cd whois
whois $TARGET > whois.txt
(echo "${SEPARATOR}\nCMD: whois $TARGET\n${SEPARATOR}#" && cat whois.txt) > whois1 && mv whois1 whois.txt
cd ..
echo "   Done\n"

echo ">> Running DNS ennumeration ... "
mkdir dns
cd dns
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

echo "   Done\n"

echo ">> Running passive subdomains enumeration ... "

curl -s https://sonar.omnisint.io/subdomains/$TARGET | jq -r '.[]' | sort -u > subdomains_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/subdomains/$TARGET | jq -r '.[]' | sort -u" && cat subdomains_sonar.txt) > sonar1 && mv sonar1 subdomains_sonar.txt

curl -s https://sonar.omnisint.io/tlds/$TARGET | jq -r '.[]' | sort -u > tlds_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/tlds/$TARGET | jq -r '.[]' | sort -u\n${SEPARATOR}\n" && cat tlds_sonar.txt) > sonar1 && mv sonar1 tlds_sonar.txt

curl -s https://sonar.omnisint.io/all/$TARGET | jq -r '.[]' | sort -u > all_tlds_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/all/$TARGET | jq -r '.[]' | sort -u\n${SEPARATOR}\n" && cat all_tlds_sonar.txt) > sonar1 && mv sonar1 all_tlds_sonar.txt

curl -s "https://crt.sh/?q=$TARGET&output=json" | jq -r '.[] | "\(.name_value)\n\(.common_name)"' | sort -u > crt_$TARGET.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s \"https://crt.sh/?q=${TARGET}&output=json\" | jq -r '.[] | \"\(.name_value)\n\(.common_name)\"' | sort -u\n\n${SEPARATOR}\n" && cat crt_${TARGET}.txt) > crt1 && mv crt1 crt_${TARGET}.txt

echo "  done\n"

echo "Running theHarvester ... "
mkdir theharvester
cd theharvester
echo "baidu
bufferoverun
crtsh
hackertarget
otx
projecdiscovery
rapiddns
sublist3r
threatcrowd
trello
urlscan
vhost
virustotal
zoomeyeecho" > sources.txt

#cat sources.txt | while read source; do theHarvester -d "${TARGET}" -b $source -f "${source}_${TARGET}";done > /dev/null

#cat *.json | jq -r '.hosts[]' 2>/dev/null | cut -d':' -f 1 | sort -u > "${TARGET}_theHarvester.txt"

#cat ${TARGET}_*.txt | sort -u > ./../${TARGET}_subdomains_passive.txt

#cat ${TARGET}_subdomains_passive.txt | wc -l

#$waybackurls -dates https://facebook.com > waybackurls.txt

echo "## Starting active information gathering ##\n"
cd ./../../../active_information_gathering
echo "Running curl on http_header ..."
mkdir http_headers
curl -I ${TARGET} > ./http_headers/${TARGET}_headers
echo "    Done\n"
echo "Running recognition of web technologies ..."
mkdir whatweb
whatweb ${TARGET} > ./whatweb/${TARGET}_whatweb
echo "    Done\n"
echo "Running web application firewall fingerprinting"
mkdir Waf
wafw00f -v ${TARGET} > ${TARGET}_wafw00f
echo "   Done\n"

mkdir subdomains
echo "Runnning subdommains enumeration"

echo ${SEPARATOR}
echo "Results written in recon_$TARGET directory"
echo ${SEPARATOR}
