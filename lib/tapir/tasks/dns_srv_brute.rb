require 'resolv'

def name
  "dns_srv_brute"
end

# Returns a string which describes what this task does
def description
  "Simple DNS Service Record Bruteforce"
end

# Returns an array of valid types for this task
def allowed_types
  [Domain]
end

def setup(entity, options={})
  super(entity, options)
  
    @resolver  = Dnsruby::DNS.new # uses system default
  
  self
end

# Default method, subclasses must override this
def run
  super
  
  if @options['srv_list']
    subdomain_list = @options['srv_list']
  else
    # Add a builtin domain list  
    srv_list = [
      '_gc._tcp', '_kerberos._tcp', '_kerberos._udp', '_ldap._tcp',
      '_test._tcp', '_sips._tcp', '_sip._udp', '_sip._tcp', '_aix._tcp',
      '_aix._tcp', '_finger._tcp', '_ftp._tcp', '_http._tcp', '_nntp._tcp',
      '_telnet._tcp', '_whois._tcp', '_h323cs._tcp', '_h323cs._udp',
      '_h323be._tcp', '_h323be._udp', '_h323ls._tcp',
      '_h323ls._udp', '_sipinternal._tcp', '_sipinternaltls._tcp',
      '_sip._tls', '_sipfederationtls._tcp', '_jabber._tcp',
      '_xmpp-server._tcp', '_xmpp-client._tcp', '_imap.tcp',
      '_certificates._tcp', '_crls._tcp', '_pgpkeys._tcp',
      '_pgprevokations._tcp', '_cmp._tcp', '_svcp._tcp', '_crl._tcp',
      '_ocsp._tcp', '_PKIXREP._tcp', '_smtp._tcp', '_hkp._tcp',
      '_hkps._tcp', '_jabber._udp','_xmpp-server._udp', '_xmpp-client._udp',
      '_jabber-client._tcp', '_jabber-client._udp','_kerberos.tcp.dc._msdcs',
      '_ldap._tcp.ForestDNSZones', '_ldap._tcp.dc._msdcs', '_ldap._tcp.pdc._msdcs',
      '_ldap._tcp.gc._msdcs','_kerberos._tcp.dc._msdcs','_kpasswd._tcp','_kpasswd._udp'
    ]
  end

  @task_logger.log_good "Using srv list: #{srv_list}"

  srv_list.each do |srv|
    begin

      # Calculate the domain name
      domain = "#{srv}.#{@entity.name}"

      # Try to resolve
      @resolver.getresources(domain, "SRV").collect do |rec|

        # split up the record
        resolved_address = rec.target
        port = rec.port
        weight = rec.weight
        priority = rec.priority

        @task_logger.log_good "Resolved Address #{resolved_address} for #{domain}" if resolved_address

        # If we resolved, create the right entitys
        if resolved_address
          @task_logger.log_good "Creating domain and host entitys..."

          # Create a domain. pass down the organization if we have it.
          d = create_entity(Domain, {:name => domain, :organization => @entity.organization })

          # Create a host to store the ip address
          h = create_entity(Host, {:ip_address => resolved_address})

          # associate the newly-created host with the domain
          d.hosts << h 
          h.domains << d
          
          # create a service, and also associate that with our host.
          h.net_svcs << create_entity(NetSvc, {:type => "tcp", :port => port, :host => h})

          # Save the raw content of our query
          #@task_run.save_raw_result rec.to_s
        end

      end
    rescue Exception => e
      @task_logger.log_error "Hit exception: #{e}"
    end


  end
end
