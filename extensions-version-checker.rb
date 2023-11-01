#!/usr/bin/ruby
require 'json'
#=========================================
unless `ping -c 1 1.1.1.1 > /dev/null 2>&1; echo $?`.to_i == 0
  puts 'ABORTING: No internet connection.'
  abort
end
#=========================================
list_enabled = `gnome-extensions list --enabled`
num_enabled_extensions = list_enabled.split("\n").length
extensions_url = 'https://extensions.gnome.org/extension-query/?search='
current_shell_ver = `gnome-shell --version`.split(' ').last
#==========================================
def sanitize(string)
  return string.gsub(' ','-').tr('^A-Za-z0-9-._','')
end
#===========================================
def search(string,i)
  kmax = 0
  parsed = JSON.parse(string)
  uuid = parsed['extensions'][i]['uuid']
  name = parsed['extensions'][i]['name']
  versions = parsed['extensions'][i]['shell_version_map']
  versions.each do |k,v|
    if k.to_i > kmax then kmax = k.to_i end
  end
  return [uuid,name,kmax]
end
#=============================================
def read_local(string)
  file = '/'+string+'/metadata.json'
  local_path_user = "#{ENV['HOME']}/.local/share/gnome-shell/extensions"
  local_path_global = '/usr/share/gnome-shell/extensions'
  type = 'Manual'+' '*7
  if File.directory? local_path_user+'/'+string
    metadata = JSON.parse(File.read(local_path_user+file))
  else
    metadata = JSON.parse(File.read(local_path_global+file))
    type = 'System'+' '*7
  end
  name = metadata['name']
  uuid = metadata['uuid']
  return[name,uuid,type]
end
#===============================================
max = 10
upgradable = 0
puts 'MAX.VER.'+' '*2+'INSTALLATION'+' '*2+"EXTENSION NAME"
puts "="*39
list_enabled.split("\n").each.with_index do |l,j|
  sleep 1 #DO NOT STRESS REMOTE SERVER
#----------read local data------------- 
  local_data = read_local(l)
#--------query remote data------------
  response_json = `curl #{extensions_url}/#{sanitize(local_data[0])} --silent`
  #-------------------------------------
  max.times do |i|
    remote_data = search(response_json,i)
      if remote_data[0]==local_data[1]
        if remote_data[2].to_i > current_shell_ver.to_i then upgradable+=1 end 
        puts remote_data[2].to_s+' '*8+local_data[2]+' '*1+local_data[0]
      break 
    end
    if i==(max-1) then puts "Could not query '#{local_data[0]}' " end
  end
end
#==================================
puts '='*39
puts 'CURRENT SHELL VERSION: ' + current_shell_ver
puts 'ENABLED EXTENSIONS: ' + num_enabled_extensions.to_s
puts 'UPGRADABLE EXTENSIONS: ' + upgradable.to_s
if upgradable == num_enabled_extensions 
  puts '-'*44
  puts "It seems all your ENABLED extensions are compatible with a newer Gnome Shell!" 
end
