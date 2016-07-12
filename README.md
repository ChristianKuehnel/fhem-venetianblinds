# fhem-venetianblinds
venetian blind controller for FHEM home automation

# License
This project is distributed under the Apache License Version 2.0

# Project status
* [![Build Status](https://travis-ci.org/ChristianKuehnel/fhem-venetianblinds.svg?branch=master)](https://travis-ci.org/ChristianKuehnel/fhem-venetianblinds)
* [![Coverage Status](https://coveralls.io/repos/github/ChristianKuehnel/fhem-venetianblinds/badge.svg?branch=master)](https://coveralls.io/github/ChristianKuehnel/fhem-venetianblinds?branch=master)


# Installation
1. Clone this repository to some local folder
2. run ```perl Makefile.PL```
3. run ```make test``` to check if the software is working on your machine.
4. If your fhem installation is *not* in ~fhem: ```export FHEM_HOME=\<path to your fhem installation\>```
5. run ```make fhem``` to deploy the files to your fhem installation
6. restart fhem and configure the module