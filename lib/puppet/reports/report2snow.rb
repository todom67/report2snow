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
		# if (self.status == "changed") then
		# 	if (self.corrective_change == true) then
		# 		real_status = "#{self.status} (corrective)"
		# 	elsif (self.corrective_change == false) then
		# 		real_status = "#{self.status} (intentional)"
		# 	else
		# 		real_status = "#{self.status} (unknown - #{self.corrective_change})"
		# 	end
		# else
		# 	real_status = "#{self.status}"
    # end
    debugFile.write("API URL: #{API_URL}\n")
    debugFile.write("REAL STATUS: #{real_status}\n")
    debugFile.write("--- closing file ---\n")
    debugFile.close
	end
end

