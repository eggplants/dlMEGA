# dlMEGA - Improved Version

[mega.nz](https://mega.nz) file downloader

## Original

- [dlMEGA](https://gist.githubusercontent.com/anonymous/86f14f9ec07421036917/raw/51229e4114ba955c80708feba98b646b289a464c/dlMEGA)
  - written in Bash script
  - hosted on <http://dlme.ga> and [AUR](https://github.com/aur-archive/dlmega) until 2017
  - © 2015 by [Herbert Knapp](https://github.com/HMKnapp) <herbert.knapp@edu.uni-graz.at>

## Usage

```shellsession
$ ./dlMEGA.sh

 dlMEGA, a mega.nz file downloader

 • Version 1.1.4, free for non-commercial use
 • © 2015 by Herbert Knapp (herbert.knapp at uni-graz.at)

 Usage: dlMEGA.sh [-p --progress-bar] [-s --stream] '<MEGA url>' ['<MEGA url>']

    eg: dlMEGA.sh --stream 'https://mega.nz/file/<id>#<key>' | mplayer -

        dlMEGA.sh -p inputfile.txt 'https://mega.nz/file/<id>#<key>'

$ ./dlMEGA.sh '<MEGA url>'

```

## Install

```bash
# Require: awk base64 curl openssl sed xxd
wget 'https://raw.githubusercontent.com/eggplants/dlMEGA/master/dlMEGA.sh'
chmod +x dlMEGA.sh

# Install /usr/local/bin if you want to run as `dlmega` anywhere
sudo install ./dlMEGA.sh /usr/local/bin/dlmega
```

## ToDo

- [x] support `mega.nz/file/<id>#<key>`
- [ ] support `mega.nz/folder/<id>#<key>`
- [ ] support `mega.nz/folder/<id>#<key>/folder/<id>/folder/<id>/...`
