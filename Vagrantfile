# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
    config.vm.box = "centos/8"
  
    config.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 2
    end
  
    config.vm.define "web" do |web|
      web.vm.network "private_network", ip: "10.0.1.4", virtualbox__intnet: "net1"
      web.vm.hostname = "web"
      web.vm.provision "shell", path: "web.sh"
    end
  
    config.vm.define "log" do |log|
      log.vm.network "private_network", ip: "10.0.1.5", virtualbox__intnet: "net1"
      log.vm.hostname = "log"
      log.vm.provision "shell", inline: <<-SHELL
        mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
      SHELL
    log.vm.provision "shell", path: "log.sh"
    end
 
  end
