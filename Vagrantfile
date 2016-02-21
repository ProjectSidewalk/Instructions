# -*- mode: ruby -*-
# vi: set ft=ruby :

$script = <<SCRIPT
echo I am provisioning...
date > /etc/vagrant_provisioned_at
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provision "shell", inline: $script

  # Bootstrap Postgres
  # config.vm.provision "shell", path: "provisioners/postgres_1.sh"
  # config.vm.provision "shell", path: "provisioners/postgres_2.sh"
  config.vm.provision "shell", path: "provisioners/postgres.sh"

  # PostgreSQL Server port forwarding
  config.vm.network "forwarded_port", guest: 5432, host: 5432

  # Django Server port forwarding
  config.vm.network "forwarded_port", guest: 8000, host: 8000
end
