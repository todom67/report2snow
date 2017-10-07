require 'puppet'
require 'yaml'
require 'json'

Puppet::Reports.register_report(:report2snow) do
  desc "Send corrective changes to ServiceNow"
  @configfile = File.join([File.dirname(Puppet.settings[:config]), "report2snow.yaml"])
  raise(Puppet::ParseError, "Servicenow report config file #{@configfile} not readable") unless File.exist?(@configfile)

  @config = YAML.load_file(@configfile)
  API_URL = config['api_url']
  USERNAME = config['username']
  PASSWORD = config['password']

	def process
    # Open a file for debugging purposes
    debugFile = File.open('/var/log/puppetlabs/puppetserver/report2snow.log','w')
    f.write("--- strating process ---\n")
    f.write("--- closing file ---\n")
    debugFile.close
	end
end

