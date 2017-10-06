require 'puppet'
require 'yaml'
require 'json'

Puppet::Reports.register_report(:report2snow) do
	if (Puppet.settings[:config]) then
		configfile = File.join([File.dirname(Puppet.settings[:config]), "report2snow.yaml"])
	else
		configfile = "/etc/puppetlabs/puppet/report2snow.yaml"
	end

	raise(Puppet::ParseError, "Config file #{configfile} not readable") unless File.exist?(configfile)
	config = YAML.load_file(configfile)

	DISABLED_FILE = File.join([File.dirname(Puppet.settings[:config]), 'report2snow_disabled'])
	API_URL = config['api_url']
    USERNAME = config['username']
    PASSWORD = config['password']

	def process
        # Find out if we should be disabled
		disabled = File.exists?(DISABLED_FILE)

        # Open a file for debugging purposes
        f = File.open('/var/log/puppetlabs/puppetserver/report2snow.log','w')

        # We only want to send a report if we have a corrective change
		if (self.status == "changed") then
			if (self.corrective_change == true) then
				real_status = "#{self.status} (corrective)"
			elsif (self.corrective_change == false) then
				real_status = "#{self.status} (intentional)"
			else
				real_status = "#{self.status} (unknown - #{self.corrective_change})"
			end
		else
			real_status = "#{self.status}"
		end

		whoami = %x( hostname -f ).chomp
	    msg = "Puppet run resulted in a status: #{real_status} in the #{self.environment} environment"
        headers = '--header "Content-Type:application/json" --header "Accept: application/json"'

        level = ''
        log_mesg = ""
        if (self.logs.length > 0) then
          self.logs.length.times do |count|
            level = self.logs[count].level

            f.write("DEBUG: [#{self.logs[count].level}] #{self.logs[count].message}\n")
            if (level =~ /info/i) then
              if( self.logs[count].message.include? "FileBucket got a duplicate file" ) then
                  log_mesg = "#{log_mesg}\n#{self.logs[count].message.chomp}"
              end
            else  
              next if self.logs[count].message.include? "{md5}"
              next if self.logs[count].message.include? "Applied catalog in"
              next if self.logs[count].message == ''
    
              #log_mesg = "#{log_mesg}\n#{self.logs[count].line} #{self.logs[count].file}\n#{self.logs[count].message.chomp}"
              f.write("Source: #{self.logs[count].line} #{self.logs[count].file}")
              log_mesg = "#{log_mesg}\n#{self.logs[count].message.chomp}"
            end

          end
        end
        log_mesg.gsub!(/"/, '') 
        log_mesg.gsub!(/'/, '') 


		#TODO give an array of status to choose from
		if (!disabled && self.corrective_change == true) then
            payload = %Q{ {
              "requested_by":"puppet notkermit",
              "type":"Standard",
              "short_description":"AUTOMATED change from Puppet detected on #{self.host}",
              "assignment_group":"Service Desk",
              "impact":"3",
              "urgency":"3",
              "risk":"3",
              "description":"#{msg}",
              "justification":"AUTOMATED change from Puppet master #{whoami}",
              "cmdb_ci":"#{self.host}",
              "start_date":"#{self.configuration_version}",
              "end_date":"#{self.configuration_version}",
              "implementation_plan":"my implementation plan",
              "u_risk_resources":"2",
              "u_risk_backout":"3",
              "u_risk_complex":"1",
              "work_notes":"Node Reports: [code]<a class='web' target='_blank' href='https://#{PUPPETCONSOLE}/#/node_groups/inventory/node/#{self.host}/reports'>Reports</a>[/code]"
            } }
        
            # We are using CURL on purpose because the rest-client requires a newer version of ruby then what's in
            # the puppetserver jruby renvironment
            result = %x(curl -v -X POST #{headers} --data '#{payload}' --user "#{USERNAME}":"#{PASSWORD}" "#{API_URL}" ) 

            f.write("-- Start of change --\n")
            f.write("API URL: #{API_URL}\n")
            f.write("Payload: #{payload}\n\n")
            f.write("Exit code: #{$?} #{$?.exitstatus}\n")
            f.write("Result: #{result}\n\n")

            # We get a json object back so we'll parse it for useful info
            data = JSON.parse(result)
            change_number = data['result']['number']

            # TODO create a "if slack enabled" hook then send over the SN info to the slack channel
            f.write("Change Number: #{change_number}\n")
            f.write("-- End of change --\n\n")

		end
        f.close
	end
end

