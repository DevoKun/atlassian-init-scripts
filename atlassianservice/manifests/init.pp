# == Define: atlassianservice
#
# Custom resource type to manage init for the Atlassian services
#
# === Parameters
#
# [*service_name*]
#   Which Atlassian service to setup init for.
#
# [*service_provider*]
#   Which Service Provider powers the init system:
#   * systemd
#   * upstart
#   * traditional init _(default)_
#
# [*java_home*]
#   The location of Java on your system.
#   This will be used like ${JAVA_HOME}/bin/java.
#   JAVA_HOME is often /usr/, or something like /usr/lib/jvm/java-8-openjdk-amd64/
#
# === Example usage:
# ```
# atlassianservice { 'jira': }
# ```
#
define atlassianservice (
  $service_name     = $name,
  $service_provider = undef,
  $java_home        = "/usr/lib/jvm/java-8-openjdk-amd64/"
) {

  unless $::osfamily =~ /(Debian|RedHat|Archlinux|Gentoo)/ {
    fail('The service class needs a Debian, RedHat, Archlinux or Gentoo based system.')
  }


  if ($service_provider == undef) {
    case $::osfamily {
      'Debian' : {
        case $::operatingsystem {
          'Ubuntu' : {
            $package_release = "ubuntu-${::lsbdistcodename}"
            if (versioncmp($::operatingsystemrelease, '15.04') >= 0) {
              $use_service_provider           = 'systemd'
            } else {
              $use_service_provider           = 'upstart'
            } ## if else
          } ### Ubuntu
          default: {
            if (versioncmp($::operatingsystemmajrelease, '8') >= 0) {
              $use_service_provider           = 'systemd'
            } else {
              $use_service_provider           = undef
            } ## if else
          } ### Default
        } ### case operatingsystem
      } ### case Debian

      'RedHat' : {
        if ($::operatingsystem == 'Fedora') or (versioncmp($::operatingsystemrelease, '7.0') >= 0) and $::operatingsystem != 'Amazon' {
          $use_service_provider           = 'systemd'
        } else {
          $use_service_provider           = undef
        } ### if else
      } ### case RedHat

      'Archlinux' : {
        $use_service_provider   = 'systemd'
      } ### case Archlinux

      'Gentoo' : {
        $use_service_provider   = 'openrc'
      } ### case Gentoo

      default: {
        $use_service_provider = undef
      } ### case default

    } ### case osfamily

  } else {
    $use_service_provider = service_provider
  } ### if else






  $install_dir      = "/opt/atlassian/$service_name"
  $bin_dir          = "$install_dir/bin"
  $service_username = $service_name

  case $service_name {
    'bamboo':     {
      $start_command = "$bin_dir/startup.sh"
      $stop_command  = "$bin_dir/shutdown.sh"
      $pid_file      = undef
    } ## bamboo
    'confluence': {
      $start_command = "$bin_dir/start-confluence.sh"
      $stop_command  = "$bin_dir/stop-confluence.sh"
      $pid_file      = "${install_dir}/work/catalina.pid"
    } ## confluence
    'stash':       {
      $start_command = "$bin_dir/start-stash.sh"
      $stop_command  = "$bin_dir/stop-stash.sh"
      $pid_file      = "/var/atlassian/application-data/stash/log/stash.pid"
    } ## stash
    'bitbucket':       {
      $start_command = "$bin_dir/start-bitbucket.sh"
      $stop_command  = "$bin_dir/stop-bitbucket.sh"
      $pid_file      = "/var/atlassian/application-data/bitbucket/log/bitbucket.pid"
    } ## bitbucket
    'jira':       {
      $start_command = "$bin_dir/start-jira.sh"
      $stop_command  = "$bin_dir/stop-jira.sh"
      $pid_file      = "${install_dir}/work/catalina.pid"
    } ## jira
    'crowd':      {
      $start_command = "$bin_dir/start_crowd.sh"
      $stop_command  = "$bin_dir/stop_crowd.sh"
      $pid_file      = "${install_dir}/apache-tomcat/work/catalina.pid"
    } ## crowd
    'fisheye':    {
      $start_command = "$bin_dir/fisheyectl.sh start"
      $stop_command  = "$bin_dir/fisheyectl.sh stop"
      $pid_file      = undef
    } ## fisheye
    default:      {
      fail('Unknown Atlassian service. Only Bamboo, Confluence, Jira, Crowd, and Fisheye are supported.')
    } ### default
  } ### case $service_name



  if ($use_service_provider == 'systemd') {

    file { "/etc/systemd/system/${service_name}.service":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => inline_template('
[Unit]
Description=Atlassian <%= @server_name %> Service
After=
Wants=
Requires=

[Service]
Restart=on-failure
StartLimitInterval=20
StartLimitBurst=5
TimeoutStartSec=0
RestartSec=5
User=<%= @service_username %>
PIDFile=<%= @pid_file %>
Environment="HOME=<%= @install_dir %>"
Environment="JAVA_HOME=<%= @java_home %>"
ExecStart=<%= @start_command %>
ExecStop=<%= @stop_command %>

[Install]
WantedBy=multi-user.target
'),
    } ### file

  } elsif ($service_provider == "openrc") {

    file { "/etc/init.d/${service_name}":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => inline_template('
#!/sbin/openrc-run
# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
#
# This file is managed by Puppet and local changes
# may be overwritten
#
#    /etc/init.d/<%= @server_name %>
#
#    Atlassian <%= @server_name %> Service

extra_commands="clean cleanRestart"

export HOME=<%= @install_dir %>
pidfile="<%= @pid_file %>"
prog="<%= @service_name %>"
if [ -d /var/lock/subsys ]; then
    lockfile="/var/lock/subsys/$prog"
else
    unset lockfile
fi

depend() {
}


start() {
  ebegin "Starting $prog:\t"
  <%= @start_command %>
  eend $?
}


stop() {
    ebegin "Stopping $prog:\t"
    <%= @stop_command %>
    eend $?
}

'),
    } ### file

  } else {

    file { "/etc/init.d/${service_name}":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => inline_template('
#!/bin/sh
#
# This file is managed by Puppet and local changes
# may be overwritten
#
#    /etc/rc.d/init.d/<%= @server_name %>
#
#    Atlassian <%= @server_name %> Service
#
# chkconfig: 2345 97 15
# description: Atlassian <%= @server_name %> Service

### BEGIN INIT INFO
# Provides:       <%= @service_prefix %><%= @sanitised_title %>
# Required-Start:
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start: 2 3 4 5
# Default-Stop:  0 1 6
# Short-Description: start and stop Atlassian <%= @server_name %> Service
# Description: Atlassian <%= @server_name %> Service
### END INIT INFO

if [ -e /etc/init.d/functions ]; then
    . /etc/init.d/functions
elif [ -e /lib/lsb/init-functions ]; then
    . /lib/lsb/init-functions
    failure() {
        log_failure_msg "$@"
        return 1
    }
    success() {
        log_success_msg "$@"
        return 0
    }
else
    failure() {
        echo "fail: $@" >&2
        exit 1
    }
    success() {
        echo "success: $@" >&2
        exit 0
    }
fi

export HOME=<%= @install_dir %>
pidfile="<%= @pid_file %>"
prog="<%= @service_name %>"
if [ -d /var/lock/subsys ]; then
    lockfile="/var/lock/subsys/$prog"
else
    unset lockfile
fi


start() {
  printf "Starting $prog:\t"
  <%= @start_command %>
  retval=$?
  echo
  if [ $retval -eq 0 ]; then
      success
  else
      failure
  fi
}


stop() {
    echo -n "Stopping $prog:\t"
    <%= @stop_command %>
    retval=$?
    echo
    if [ $retval -eq 0 ]; then
      success
    else
      failure
    fi
    return $retval
}

clean() {
    if ! [ -f $pidfile ]; then
        failure
        echo
        printf "$pidfile does not exist.\n"
    else
        pid="$(cat $pidfile)"
        rm $pidfile
        retval=$?
        return $retval
    fi
}

case "$1" in
    start)
    start
    ;;
    stop)
    stop
    ;;
    status)
    echo
    ;;
    restart|reload)
    stop
    start
    ;;
    clean)
    clean
    ;;
    cleanRestart)
    stop
    clean
    start
    ;;
    condrestart)
    [ -f /var/lock/subsys/$prog ] && restart || :
    ;;
    *)
    echo "Usage: $0 [start|stop|status|reload|restart|probe|clean|cleanRestart]"
    exit 1
    ;;
esac
exit $?


'),
    } ### file

  } ### if else


} ### class

