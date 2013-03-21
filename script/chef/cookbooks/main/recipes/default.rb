# Install basic packages
%w(git-core vim).each do |p|
  package p
end

# Create users
user node[:user][:name] do
  password node[:user][:password]
  gid "sudo"
  shell "/bin/bash"
  home "/home/#{node[:user][:name]}"
  supports manage_home: true
end
