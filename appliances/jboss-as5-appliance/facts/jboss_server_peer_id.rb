Facter.add("jboss_server_peer_id") do
  setcode do
    a,b,c,d = Facter[:ipaddress].value.to_s.split( '.' )
    "#{d}"
  end
end
