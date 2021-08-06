#!/bin/bash

if [ ${UID} -ne 0 ];then
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') \033[32mINFO\033[0m please use root to execute install shell"
  exit 1
fi

function env_check() {
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') \033[32mINFO\033[0m environment checking"

    env_ok=true
    sshpass_has="✓"
    conntrack_has="✓"
    unzip_has="✓"

    which sshpass > /dev/null
    if [ $? != 0 ]; then
      sshpass_has="x"
      env_ok=false
    fi

    which conntrack > /dev/null
    if [ $? != 0 ]; then
      conntrack_has="x"
      env_ok=false
    fi

    which unzip > /dev/null
    if [ $? != 0 ]; then
      unzip_has="x"
      env_ok=false
    fi

    echo -e "\033[32m|---------------------------------------------------|\033[0m"
    echo -e "\033[32m|     sshpass     |    conntrack    |      unzip    |\033[0m"
    echo -e "\033[32m|---------------------------------------------------|\033[0m"
    echo -e "\033[32m|     ${sshpass_has}           |    ${conntrack_has}            |      ${unzip_has}        |\033[0m"
    echo -e "\033[32m|---------------------------------------------------|\033[0m"

    if [ ${env_ok} = false ]; then
        echo -e "$(date +'%Y-%m-%d %H:%M:%S') \033[32mINFO\033[0m lack of dependencies, ensure them"
        exit 1
    fi
}

env_check

mkdir -p /etc/kubecube
mkdir -p /etc/kubecube/down
mkdir -p /etc/kubecube/bin
cd /etc/kubecube

if [ -e "./manifests" ]; then
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') \033[32mINFO\033[0m manifests already exist"
else
  echo -e "$(date +'%Y-%m-%d %H:%M:%S') \033[32mINFO\033[0m downloading manifests for kubecube"
  wget https://kubecube.nos-eastchina1.126.net/kubecube-installer/v1.0.0/manifests.tar.gz -O manifests.tar.gz

  tar -xzvf manifests.tar.gz > /dev/null
fi

if [[ ${CUSTOMIZE} = "true" ]]; then
  echo -e "\033[32m================================================\033[0m"
  echo -e "\033[32m 1. Please make sure under kubecube folder      \033[0m"
  echo -e "\033[32m 'cd /etc/kubecube/manifests'                   \033[0m"
  echo -e "\033[32m 2. Please modify install.conf                  \033[0m"
  echo -e "\033[32m 'vi install.conf'                              \033[0m"
  echo -e "\033[32m 3. Please modify cube.conf(optional)           \033[0m"
  echo -e "\033[32m 'vi cube.conf'                                 \033[0m"
  echo -e "\033[32m 4. Confirm every args then do command below:   \033[0m"
  echo -e "\033[32m '/bin/bash install.sh'                         \033[0m"
  echo -e "\033[32m================================================\033[0m"
  exit 0
fi

/bin/bash /etc/kubecube/manifests/install.sh
