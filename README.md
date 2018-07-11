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
update-rc.d jira defaults
service     jira start
```

## SystemD
* Copy the service script in to /etc/systemd/system/

```
systemctl enable jira.service
systemctl start  jira.service
systemctl status jira.service
```


## Migrating from SysV Init Scripts to SystemD
* If you have used the Atlassian installer, _instead of the zip,_ or created an init script and want to migrate to SystemD, here are the steps.

### Stop and disable the running service
```
service jira stop

## Ubuntu
update-rc.d jira disable && update-rc.d jira remove

## RHEL
chkconfig jira off && chkconfig httpd --del
```

### Remove the old init scripts
```
find /etc/init/   -iname \*jira\* -delete
find /etc/init.d/ -iname \*jira\* -delete
```

### Install the systemd service script and start the service
* Copy the systemd service script in to /etc/systemd/system/
```
cp jira.service /etc/systemd/system/
```

* Start the service
```
systemctl enable jira.service
systemctl start  jira.service
systemctl status jira.service
```




## Using the Puppet Module
* **atlassianservice** can be used to generate the init scripts required by the Atlassian services.

```
atlassianservice { 'jira': }
```

* Place the **atlassianservice** directory in to your **modules** directory to use it.








