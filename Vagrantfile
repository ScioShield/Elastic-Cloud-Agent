Vagrant.configure("2") do |config|
config.vm.define "windows" do |windows|
    windows.vm.box = "gusztavvargadr/windows-10-21h2-enterprise"
    windows.vm.hostname = 'windows-agent-8-6'
    windows.vm.box_url = "gusztavvargadr/windows-10-21h2-enterprise"
    windows.vm.network :private_network, ip: "10.0.0.30"
    windows.vm.provider :virtualbox do |v|
     v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
     v.customize ["modifyvm", :id, "--cpus", 2]
     v.customize ["modifyvm", :id, "--memory", 4096]
     v.customize ["modifyvm", :id, "--nested-hw-virt", "off"]
     v.customize ["modifyvm", :id, "--pae", "off"]
     v.customize ["modifyvm", :id, "--name", "windows-agent-8-6"]
    end
  end
end