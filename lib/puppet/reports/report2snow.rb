require 'puppet'
require 'yaml'
require 'json'

Puppet::Reports.register_report(:report2snow) do
  desc "Send corrective changes to ServiceNow"
  @configfile = File.join([File.dirname(Puppet.settings[:config]), "report2snow.yaml"])
  raise(Puppet::ParseError, "Servicenow report config file #{@configfile} not readable") unless File.exist?(@configfile)

  @config = YAML.load_file(@configfile)
  API_URL = @config['api_url']
  USERNAME = @config['username']
  PASSWORD = @config['password']

	def process
    # Open a file for debugging purposes
    debugFile = File.open('/var/log/puppetlabs/puppetserver/report2snow.log','w')
    debugFile.write("--- starting process ---\n")
    # We only want to send a report if we have a corrective change
    self.status == "changed" && self.corrective_change == true ? real_status = "#{self.status} (corrective)" : real_status = "#{self.status}" 
    msg = "Puppet run resulted in a status: #{real_status} in the #{self.environment} environment"
    debugFile.write("MSG: #{msg}\n")

    if real_status == 'changed (corrective)' then
      debugFile.write("We have a #{real_status} so we are going to call service now\n")  
    end
    
    
    debugFile.write("--- closing file ---\n")
    debugFile.close
	end
end

