# Ubuntu-Kiosk

Configures a fresh installation of Xubuntu to convert it into a kiosk which
only runs a web application within Google Chrome. A user is created, named
kiosk, whose account can only be accessed by automatically launching an X
session (password is disabled). That X session doesn't include any desktop
environment but instead runs Google Chrome in fullscreen kiosk mode.

Note: by default Chrome will be directed to http://localhost. Change the
variable WEB\_APP\_URL to redirect somewhere else.

## Usage

Launch as root (or with root permissions):

```bash
$ sudo ./configure-kiosk.sh
```

## Tested on

+ Xubuntu 17.04

Other Ubuntu relatives will probably work fine, but I've only tested it on
the above list.

