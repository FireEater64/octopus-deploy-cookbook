# frozen_string_literal: true
#
# Author:: Brent Montague (<bmontague@cvent.com>)
# Cookbook Name:: octopus-deploy-test
# Recipe:: server
#
# Copyright:: Copyright (c) 2015 Cvent, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Create a user to run the tentacle as (the cookbook assumes the user is already present)
service_user = 'octopus_server'
service_password = '5up3rR@nd0m'

user service_user do
  action :create
  password service_password
end

sa_password = '!40XS7qwrpZpD0mTE!'

sql_server_install 'Install SQL Server Express 2017' do
  version '2017'
  netfx35_install false
  sql_reboot false
  accept_eula true
  sysadmins service_user
  security_mode 'Mixed Mode Authentication'
  sa_password sa_password
end

octopus_database = "Octopus"

powershell_script 'create database' do
  code "& 'C:\\Program Files\\Microsoft SQL Server\\Client SDK\\ODBC\\130\\Tools\\Binn\\SQLCMD.EXE' -S .\\SQLEXPRESS -Q 'CREATE DATABASE #{octopus_database};'"
end

# We remove and then configure everything everytime
octopus_deploy_server 'OctopusServer' do
  action [:uninstall, :install, :remove, :configure]
  version node['octopus-deploy-test']['server']['version']
  checksum node['octopus-deploy-test']['server']['checksum']
  node_name 'octo-web-01'
  connection_string "Data Source=(local)\\SQLEXPRESS;Database=#{octopus_database};User Id=sa;Password=#{sa_password}"
  master_key node['octopus-deploy-test']['server']['master-key']
  start_service node['octopus-deploy-test']['server']['start-service']
  create_database node['octopus-deploy-test']['server']['create-database']
end
