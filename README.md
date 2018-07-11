Init scripts for the Atlassian suite of services 
================================================

* These are init scripts that can be used with Debian/Ubuntu to start the Atlassian suite of services.
* The scripts are designed to work with: bamboo, bitbucket, confluence, crowd, fisheye, jira, or stash.

* The scripts all assume you have installed the Atlassian packages, using a zip file, to: /opt/atlassian/$service_name

* Versions of Ubuntu before 15.04 can make use of the SysV init scripts.
* Versions of Ubuntu 15.04, and later, can make use of the SystemD scripts.


## SysV Init Scripts
* Copy the init script in to /etc/init.d
* Then use **update-rc.d** to register the service to start at the appropriate runlevels.

```
update-rc.d $service_name defaults
service $service_name start
```

## SystemD
* Copy the service script in to /etc/systemd/system/

```
systemctl enable jira.service
systemctl start jira.service
systemctl status jira.service
```



## Using the Puppet Manifest
* **atlassianservice.pp** can be used to generate the init scripts required by the Atlassian services.

```
atlassianservice { 'jira': }
```










