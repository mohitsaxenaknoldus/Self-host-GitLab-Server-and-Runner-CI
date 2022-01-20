# Self-hosted GitLab CI on GitHub repos over Tor (for a Raspberry Pi 4b)

This repository first sets up wifi on a Raspberry Pi 4b (with 4gb ram) and then it starts the following services:
 - A GitLab server over Tor such that you can host- and access it yourself, anywhere, for free, anonymously.
 - Applies GitLab CI to all the GitHub repositories you choose.
 These services are started using a cronjob.


## Setup GitLab server + GitLab runner CI
Install Anaconda (if you already did this/have `conda`, skip it) (open terminal and run):
```
sudo apt update
yes | sudo apt install curl
yes | sudo apt install wget
wget -O ~/Downloads/anaconda.sh https://repo.anaconda.com/archive/Anaconda3-2021.11-Linux-x86_64.sh
bash ~/Downloads/anaconda.sh -b -p $HOME/anaconda3
reboot -n
```
Install this repository (which uses Anaconda):
```
sudo apt update
yes | sudo apt install curl
yes | sudo apt install wget
yes | sudo apt install git
yes | git clone https://github.com/Simple-Setup/Self-host-GitLab-Server-and-Runner-CI.git
cd Self-host-GitLab-Server-and-Runner-CI
chmod +x *.sh
./install_gitlab.sh -s -r
```

## Testing
After GitLab, and its runner CI is installed and running, you can run the tests with: 
```
rm -r test/libs/*
chmod +x *.sh
./install-bats-libs.sh
./test.sh
```
Alternatively to running all tests with `./test.sh`, you can run a single testfile with:
```
./test/libs/bats/bin/bats test/test_helper_gitlab_modify.bats
```
 ## First-time usage Raspberry Pi 4B
 Copy the `first_time_rpi_4b.sh` script to the Raspberry Pi 4B via a USB stick with code:
```
TODO
```
TODO: automatically download this GitHub and automatically set up the cronjob to establish the Tor connection upon boot.
TODO: Scan for private input data to claim accompanying domains.
TODO: Ensure that the SSH access is set up automatically towards the parent pc.


## Establish Tor connection upon boot:
Create a cronjob that runs the file:
`torssh.sh`


## Setup Website
TODO: Run script that sets up website server once the tor connection is enabled.
TODO: Create script that detects once the Website has been established, continuously monitor and reboot upon failure.


## Setup SSH service upon boot
TODO: Create script that adds a cronjob for this task.
TODO: Create script that verifies the SSH is available.
