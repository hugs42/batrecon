#!/bin/bash

RED="e[31m"
GREEN="32"
BOLDRED="\e[1;${RED}m"
BOLDGREEN="\e[1;${GREEN}m"
ENDCOLOR="\e[0m"
SEPARATOR="#########################################################################"
IP=0
MODE=1
TLS=0

echo "
    ____        __  
   / __ )____ _/ /_________  _________  ____
  / __  / __ \`/ __/ ___/ _ \/ ___/ __ \/ __ \\
 / /_/ / /_/ / /_/ /  /  __/ /__/ /_/ / / / /
/_____/\__,_/\__/_/   \___/\___/\____/_/ /_/ 

"

if [ "$EUID" -ne 0 ]; then
  echo "Please run it as root"
  echo "Usage: sudo bash batrecon.sh <ip/url>" >&2
  exit 1
elif [ "$#" -ne 1 ]; then
  echo "Usage: sudo bash batrecon.sh <ip/url>" >&2
  exit 1
else
  TARGET=$1
fi

if [[ ${TARGET::7} == "http://" ]]; then
  $TARGET=${TARGET:7}
elif [[ ${TARGET::8} == "https://" ]]; then
  $TARGET=${TARGET:8}
fi

if [ -d "$TARGET" ]; then
  echo -n "Warning: the target $TARGET already exist ...
Would you want to relaunch the recon script and overwrite (y/N)?
"
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
  if echo "$answer" | grep -iq "^y" ;then
      rm -rf $TARGET
  else
      echo "Exit"
      exit 1
  fi
fi

mkdir ${TARGET}

if [ -d "${TARGET}" ]; then
  echo "Would you like to perform a full recon against ${TARGET} ?"
  echo "   - 1: Perform a full recon (both passive and active)"
  echo "   - 2: Perform passive recon"
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
  if echo "$answer" | grep -iq "^1" ;then
      ${MODE}=1
  else
      ${MODE}=2
  fi
fi

if [ ${MODE}=1 ]; then
  if [ ping -c 1 -W 1 "$TARGET" > /dev/null 2> /dev/null ]; then
   echo "OK: Target ->> $TARGET <<-"
  else
      echo "Target $TARGET doesn't seems to be reachable"
     exit 1
  fi
fi


touch ./$TARGET/recon.txt
echo "
    ____        __  
   / __ )____ _/ /_________  _________  ____
  / __  / __ \`/ __/ ___/ _ \/ ___/ __ \/ __ \\
 / /_/ / /_/ / /_/ /  /  __/ /__/ /_/ / / / /
/_____/\__,_/\__/_/   \___/\___/\____/_/ /_/ 

" > ./$TARGET/recon.txt
echo $SEPARATOR > ./$TARGET/recon.txt

sudo apt update > /dev/null 2>&1

if ! [ -x "$(command -v git)" ]; then
  echo 'Download and installation of git' >&2
  sudo apt install git -y > /dev/null
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Download and installation of jq' >&2
  sudo apt install jq -y > /dev/null
fi

if ! [ -x "$(command -v python3)" ]; then
  echo 'Download and installation of python3' >&2
  sudo apt install python3 -y > /dev/null
fi

if ! [ -x "$(command -v pip)" ]; then
  echo 'Download and installation of pip' >&2
  sudo apt install pip -y > /dev/null
fi

if ! [ -x "$(command -v dig)" ]; then
  echo 'Download and installation of dnsutils' >&2
  sudo apt install dnsutils -y > /dev/null
fi

if ! [ -x "$(command -v go)" ]; then
  echo 'Download and installation of go' >&2
  wget https://go.dev/dl/go1.17.6.linux-amd64.tar.gz > /dev/null
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.6.linux-amd64.tar.gz > /dev/null
  export PATH=$PATH:/usr/local/go/bin
  rm go1.17.6.linux-amd64.tar.gz
fi

if ! [ -x "$(command -v whois)" ]; then
  echo 'Download and installation of whois' >&2
  sudo apt install whois -y > /dev/null
fi

if ! [ -x "$(command -v whatweb)" ]; then
  echo 'Download and installation of whatweb' >&2
  sudo apt install whatweb -y > /dev/null
fi

if ! [ -x "$(command -v rustscan)" ]; then
  echo 'Download and installation of rustscan' >&2
  wget https://github.com/RustScan/RustScan/releases/download/2.0.1/rustscan_2.0.1_amd64.deb -y > /dev/null
  dpkg -i rustscan_2.0.1_amd64.deb
fi

if ! [ -x "$(command -v theHarvester)" ]; then
  echo 'Download and installation of theHarvester' >&2
  cd $TARGET
  git clone https://github.com/laramies/theHarvester > /dev/null
  cd theHarvester
  python3 -m pip install -r requirements/base.txt > /dev/null
  cd ./../../
fi

if ! [ -x "$(command -v chromium)" ]; then
  echo 'Download and installation of chromium' >&2
  sudo apt install chromium -y > /dev/null
fi

if ! [ -x "$(command -v nikto)" ]; then
  echo 'Download and installation of nikto\n' >&2
  sudo apt install nikto -y > /dev/null
fi

if ! [ -x "$(command -v raccoon)" ]; then
  echo 'Download and installation of raccoon-scanner' >&2
  sudo pip install raccoon-scanner > /dev/null
fi

#if ! [ -x "$(command -v aquatone)" ]; then
#  echo 'Download and installation of aquatone\n' >&2
#  sudo apt install golang chromium-driver -y > /dev/null
#  wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip > /dev/null
#  cd a
#  go install github.com/michenriksen/aquatone@latest > /dev/null
#  export PATH="$PATH":"$HOME/go/bin"
#fi

#if ! [ -x "$(command -v waybackurls)" ]; then
#  echo 'Download and installation of waybackurls' >&2
#  go install github.com/tomnomnom/waybackurls@latest > /dev/null
#fi

cd $TARGET
echo "
## Starting passive information gathering ##
"
echo ">> Running whois lookup..."
whois $TARGET > whois.txt
(echo "${SEPARATOR}\nCMD: whois $TARGET\n${SEPARATOR}#" && cat whois.txt) > whois1 && mv whois1 whois.txt
echo "   Done
"

echo ">> Running DNS ennumeration..."
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

echo "   Done
"

echo ">> Running passive subdomains enumeration... "

curl -s https://sonar.omnisint.io/subdomains/$TARGET | jq -r '.[]' | sort -u > subdomains_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/subdomains/$TARGET | jq -r '.[]' | sort -u" && cat subdomains_sonar.txt) > sonar1 && mv sonar1 subdomains_sonar.txt

curl -s https://sonar.omnisint.io/tlds/$TARGET | jq -r '.[]' | sort -u > tlds_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/tlds/$TARGET | jq -r '.[]' | sort -u\n${SEPARATOR}\n" && cat tlds_sonar.txt) > sonar1 && mv sonar1 tlds_sonar.txt

curl -s https://sonar.omnisint.io/all/$TARGET | jq -r '.[]' | sort -u > all_tlds_sonar.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s https://sonar.omnisint.io/all/$TARGET | jq -r '.[]' | sort -u\n${SEPARATOR}\n" && cat all_tlds_sonar.txt) > sonar1 && mv sonar1 all_tlds_sonar.txt

curl -s "https://crt.sh/?q=$TARGET&output=json" | jq -r '.[] | "\(.name_value)\n\(.common_name)"' | sort -u > crt_$TARGET.txt
(echo "${SEPARATOR}\nCMD:\ncurl -s \"https://crt.sh/?q=${TARGET}&output=json\" | jq -r '.[] | \"\(.name_value)\n\(.common_name)\"' | sort -u\n\n${SEPARATOR}\n" && cat crt_${TARGET}.txt) > crt1 && mv crt1 crt_${TARGET}.txt

echo "   Done
"

echo ">> Running theHarvester..."
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

rm sources.txt
echo "   Done
"
#$waybackurls -dates https://facebook.com > waybackurls.txt

echo "## Starting active information gathering ##
"
cd ./../../
echo ">> Running curl on http_header..."
curl -s -I ${TARGET} > http_headers.txt
echo "   Done
"
echo ">> Check if TLS enabled..."
nmap --script ssl-enum-ciphers -p 443 10.10.11.148 | grep TLS | wc -l > tls.txt
TMP=`cat tls.txt`
if [ "${TMP}" != "0" ]; then
    $TLS=1
fi
rm tls.txt
echo "   Done
"

echo ">> Running recognition of web technologies..."
whatweb ${TARGET} -v > whatweb.txt
echo "   Done
"
echo ">> Running web application firewall fingerprinting..."
if [ "${TLS}" == 0 ]; then
  wafw00f http://${TARGET} > wafw00f.txt
else
  wafw00f https://${TARGET} > wafw00f.txt
fi
echo "   Done
"

#echo "Runnning subdommains enumeration"

echo ">> Runnning nmap host discovery..."

echo ">> Running port scan..."
sudo rustscan -b 924 -a ${TARGET} > rustscan.txt
cat rustscan.txt | grep "open  " | cut -c1-2 | wc -l > nb_ports.txt
${TMP}=`cat nb_ports.txt`
cat rustscan.txt | grep "open  " | cut -c1-2 > open_ports.txt
#sudo nmap -A -sC -P -O ${TARGET} > nmap_tcp.txt
#sudo nmap -sUV -T4 -F --version-intensity 0 ${TARGET} > nmap_udp.txt
rm nb_ports.txt && rm open_ports.txt
echo "   Done
"
echo ">> Running nikto..."
nikto -h https://${TARGET} > nikto.txt
sudo nmap ${TARGET} -s - -oA tnet > ./host_discovery
echo "   Done
"
echo ">> Running raccon-scanner..."
raccoon ${TARGET} > /dev/null
echo "   Done
"

echo ${SEPARATOR}
echo "   End of script"
echo "   Results written in $TARGET directory"
echo ${SEPARATOR}
