Puppet module for create sysv, openrc, and systemd init scripts for use with Atlassian services.

## Example


```puppet

atlassianservice { 'jira': }

atlassianservice { 'bamboo':     service_provider=>"systemd" }

```
