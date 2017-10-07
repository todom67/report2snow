# report2snow

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with report2snow](#setup)
    * [What report2snow affects](#what-report2snow-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with report2snow](#beginning-with-report2snow)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)

## Description

report2snow uses the Puppet Reporting API to open new incidents in ServiceNow if
there have been corrective changes.

## Setup

### What report2snow affects

On the Puppet Master, this module:

* adds configuration to /etc/puppetlabs/puppet/puppet.conf
* creates the configuration file /etc/puppetlabs/puppet/report2snow.yaml
* Adds a ruby plugin to commuincate with the ServiceNow API
* Create the log file /var/log/puppetlabs/puppetserver/report2snow.log

### Setup Requirements

report2snow requires the rest-client gem.

```bash
puppetserver gem install rest-client
```

**NOTE: depending on your PE version, the bundled ruby version may not be supported. In
that case you may need a previous version of the rest-client gem, such as:

```bash
puppetserver gem install rest-client -v 2.0.0.rc2 --pre
```

### Beginning with report2snow

There are 4 steps to the report2snow configuration:

* declare the report2snow class in a manifest:

```puppet
class { '::report2snow':
  url            => 'https://<YOUR SERVICENOW INSTANCE HERE>/api/now/table/incident',
  puppet_console => 'https://<YOUR CONSOLE HERE>',
}
```

* run puppet - This will create the file /etc/puppetlabs/puppet/report2snow.yaml with content similar to this:

```yaml
---
api_url: "https://<YOUR SERVICENOW INSTANCE HERE>/api/now/table/incident"
console_url: "https://<YOUR CONSOLE HERE>"
debug: false
# add servicenow username and password below
username: PROVIDE_THE_SERVICENOW_USER
password: PROVIDE_THE_PASSWORD
```

* Edit /etc/puppetlabs/puppet/report2snow.yaml. Add the ServiceNow username and password:

```yaml
---
api_url: "https://<YOUR SERVICENOW INSTANCE HERE>/api/now/table/incident"
console_url: "https://<YOUR CONSOLE HERE>"
debug: false
# add servicenow username and password below
username: <SERVICENOW USER>
password: <PASSWORD>
```

* restart the puppetserver service:

```bash
systemctl restart pe-puppetserver
```

## Usage

Once set up, there is nothing more to do. Corrective changes will be reported to ServiceNow and a simple log entry containing the node, environment and ServiceNow Incident will be added to /var/log/puppetlabs/puppetserver/report2snow.log.

```bash
[2017-10-07T18:17:26Z]: Puppet run on ip-172-31-32-95.us-west-2.compute.internal resulted in a status of changed (corrective) in the production environment
[2017-10-07T18:17:26Z]: ServiceNow Incident INC0010009 was created on 2017-10-07 18:17:26
```

There is also debugging log option that can be turned on which will add debug messages to /var/log/puppetlabs/puppetserver/report2snow.log.
Set ```debug: true``` in /etc/puppetlabs/puppet/report2snow.yaml and restart the puppetserver service.

When there are corrective changes and debgugging is turned on, your log will contain much for info:

```bash
[2017-10-07T18:27:53Z]: DEBUG: msg: Puppet run resulted in a status of 'unchanged'' in the 'production' environment
[2017-10-07T18:30:13Z]: DEBUG: msg: Puppet run resulted in a status of 'changed (corrective)'' in the 'production' environment
[2017-10-07T18:30:13Z]: DEBUG: payload:
-------
{:active=>"false", :category=>"Puppet Corrective Change", :description=>"Puppet run resulted in a status of 'changed (corrective)'' in the 'production' environment", :escalation=>"0", :impact=>"1", :incident_state=>"3", :priority=>"2", :severity=>"1", :short_description=>"Puppet Corrective Change on ip-172-31-32-95.us-west-2.compute.internal", :state=>"7", :sys_created_by=>"Puppet but not Kermit", :urgency=>"1", :work_notes=>"Node Reports: [code]<a class='web' target='_blank' href='https://puppet.aws.aheadaviation.com/#/node_groups/inventory/node/ip-172-31-32-95.us-west-2.compute.internal/reports'>Reports</a>[/code]"}
-----
[2017-10-07T18:30:13Z]: DEBUG: response:
-------
{"result":{"parent":"","made_sla":"true","caused_by":"","watch_list":"","upon_reject":"cancel","sys_updated_on":"2017-10-07 18:30:15","child_incidents":"0","hold_reason":"","approval_history":"","number":"INC0010010","resolved_by":{"link":"https://dev31247.service-now.com/api/now/table/sys_user/6816f79cc0a8016401c5a33be04be441","value":"6816f79cc0a8016401c5a33be04be441"},"sys_updated_by":"admin","opened_by":{"link":"https://dev31247.service-now.com/api/now/table/sys_user/6816f79cc0a8016401c5a33be04be441","value":"6816f79cc0a8016401c5a33be04be441"},"user_input":"","sys_created_on":"2017-10-07 18:30:15","sys_domain":{"link":"https://dev31247.service-now.com/api/now/table/sys_user_group/global","value":"global"},"state":"7","sys_created_by":"admin","knowledge":"false","order":"","calendar_stc":"0","closed_at":"2017-10-07 18:30:15","cmdb_ci":"","delivery_plan":"","impact":"1","active":"false","work_notes_list":"","business_service":"","priority":"1","sys_domain_path":"/","rfc":"","time_worked":"","expected_start":"","opened_at":"2017-10-07 18:30:15","business_duration":"1970-01-01 00:00:00","group_list":"","work_end":"","caller_id":"","resolved_at":"2017-10-07 18:30:15","approval_set":"","subcategory":"","work_notes":"","short_description":"Puppet Corrective Change on ip-172-31-32-95.us-west-2.compute.internal","close_code":"","correlation_display":"","delivery_task":"","work_start":"","assignment_group":"","additional_assignee_list":"","business_stc":"0","description":"Puppet run resulted in a status of 'changed (corrective)'' in the 'production' environment","calendar_duration":"1970-01-01 00:00:00","close_notes":"","notify":"1","sys_class_name":"incident","closed_by":{"link":"https://dev31247.service-now.com/api/now/table/sys_user/6816f79cc0a8016401c5a33be04be441","value":"6816f79cc0a8016401c5a33be04be441"},"follow_up":"","parent_incident":"","sys_id":"6f9e856f4fe503006ad47d218110c704","contact_type":"","incident_state":"7","urgency":"1","problem_id":"","company":"","reassignment_count":"0","activity_due":"","assigned_to":"","severity":"1","comments":"","approval":"not requested","sla_due":"","comments_and_work_notes":"","due_date":"","sys_mod_count":"0","reopen_count":"0","sys_tags":"","escalation":"0","upon_approval":"proceed","correlation_id":"","location":"","category":"inquiry"}}
-----
[2017-10-07T18:30:13Z]: Puppet run on ip-172-31-32-95.us-west-2.compute.internal resulted in a status of changed (corrective) in the production environment
[2017-10-07T18:30:13Z]: ServiceNow Incident INC0010010 was created on 2017-10-07 18:30:15

```

## Reference

Here, include a complete list of your module's classes, types, providers,
facts, along with the parameters for each. Users refer to this section (thus
the name "Reference") to find specific details; most users don't read it per
se.
