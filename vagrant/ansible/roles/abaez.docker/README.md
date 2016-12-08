Docker
=========
[![license][2i]][2p]

Install docker with docker-compose for a number of linux variants.

Usage
-----

All you need to do is make sure you are running the role as a privileged user and append to playbook like so::

``` yaml
- hosts: servers
    roles:
        - abaez.docker
```

Author Information
------------------

[Alejandro Baez][1]

[1]: https://keybase.io/baez
[2i]: https://img.shields.io/badge/license-BSD_2-blue.svg
[2p]: ./LICENSE
