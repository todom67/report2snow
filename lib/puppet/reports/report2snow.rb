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
  PUPPETCONSOLE = @config['console_url']

	def process
    # Open a file for debugging purposes
    debugFile = File.open('/var/log/puppetlabs/puppetserver/report2snow.log','a')

    # We only want to send a report if we have a corrective change
    self.status == "changed" && self.corrective_change == true ? real_status = "#{self.status} (corrective)" : real_status = "#{self.status}" 
    msg = "Puppet run resulted in a status of '#{real_status}'' in the '#{self.environment}' environment"

    if real_status == 'changed (corrective)' then
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
        :work_notes => "Node Reports: [code]<a class='web' target='_blank' href='#{PUPPETCONSOLE}/#/node_groups/inventory/node/#{self.host}/reports'>Reports</a>[/code]"
      }
      response = RestClient.post("#{SN_URL}",
                                   request_body_map.to_json,    # Encode the entire body as JSON
                                  {
                                    :authorization => "Basic #{Base64.strict_encode64("#{SN_USERNAME}:#{SN_PASSWORD}")}",
                                    :content_type => 'application/json',
                                    :accept => 'application/json'}
                                )
      responseData = JSON.parse(response)
      incidentNumber = responseData['result']['number']
      created = responseData['result']['opened_at']
      timestamp = Time.now.utc.iso8601
      debugFile.write("[#{timestamp}]: Puppet run on #{self.host} resulted in a status of #{real_status} in the #{self.environment} environment\n")
      debugFile.write("[#{timestamp}]: ServiceNow Incident #{incidentNumber} was created on #{created}\n")
    end
    debugFile.close
	end
end
