require 'puppet'
require 'yaml'
require 'json'
require 'rest-client'
require 'base64'

Puppet::Reports.register_report(:report2snow) do
  desc "Send corrective changes to ServiceNow"
  @configfile = File.join([File.dirname(Puppet.settings[:config]), "report2snow.yaml"])
  raise(Puppet::ParseError, "Servicenow report config file #{@configfile} not readable") unless File.exist?(@configfile)

  @config = YAML.load_file(@configfile)
  SN_URL = @config['api_url']
  SN_USERNAME = @config['username']
  SN_PASSWORD = @config['password']

	def process
    # Open a file for debugging purposes
    debugFile = File.open('/var/log/puppetlabs/puppetserver/report2snow.log','w')
    debugFile.write("--- starting process ---\n")
    # We only want to send a report if we have a corrective change
    self.status == "changed" && self.corrective_change == true ? real_status = "#{self.status} (corrective)" : real_status = "#{self.status}" 
    msg = "Puppet run resulted in a status of '#{real_status}'' in the '#{self.environment}' environment"

    if real_status == 'changed (corrective)' then
      debugFile.write("We have a #{real_status} so we are going to call service now\n")
      request_body_map = {
        :active => 'false',
        :category => 'Puppet Corrective Change',
        :description => "#{msg}",
        :escalation => '0',
        :impact => '1',
        :incident_state => '3',
        :priority => '2',
        :severity => '1',
        :short_description => "Puppet Corrective Change on #{self.host}",
        :state => '7',
        :sys_created_by => 'Puppet but not Kermit',
        :urgency => '1',
        :work_notes => "Node Reports: [code]<a class='web' target='_blank' href='https://#{PUPPETCONSOLE}/#/node_groups/inventory/node/#{self.host}/reports'>Reports</a>[/code]"
      }
      debugFile.write("Payload: #{request_body_map}")
      debugFile.write("Done!!\n")  
    end
    
    
    debugFile.write("--- closing file ---\n")
    debugFile.close
	end
end

