# the downloaded zip file.
bginfo_zip_file                 = ::File.basename(node['SysinternalsBginfo']['sysinternals_download_url'])

# the bginfo configuration file (typically Config.bgi).
bginfo_bgi_configuration_file   = "#{node['SysinternalsBginfo']['bginfo_installation_directory']}\\Config.bgi"

# create the local by downloading the remote file from sysinternals
remote_file "#{Chef::Config[:file_cache_path]}/#{bginfo_zip_file}" do
  source node['SysinternalsBginfo']['sysinternals_download_url']
  notifies :unzip, "windows_zipfile[bginfozip]", :immediately
end

# unzip the downloaded file to the installation directory
windows_zipfile "bginfozip" do
  path node['SysinternalsBginfo']['bginfo_installation_directory']
  source "#{Chef::Config[:file_cache_path]}/#{bginfo_zip_file}"
  action :unzip
  not_if { ::File.exists?("#{node['SysinternalsBginfo']['bginfo_installation_directory']}/bginfo.exe") }
end

# create the bginfo configuration file if it doesn't exist
cookbook_file bginfo_bgi_configuration_file do
  source "Config.bgi"
  action :create_if_missing
end

# reset the bginfo configuration file permissions
execute "fix-permissions" do
  command "icacls #{bginfo_bgi_configuration_file} /reset"
  action :nothing
end

# set windows to automatically run bginfo by creating a registry value
windows_auto_run 'BGINFO' do
  program "#{node['SysinternalsBginfo']['bginfo_installation_directory']}\\bginfo.exe"
  args "\"#{bginfo_bgi_configuration_file}\" /NOLICPROMPT /TIMER:0"
  not_if { Registry.value_exists?(AUTO_RUN_KEY, 'BGINFO') }
  action :create
end
