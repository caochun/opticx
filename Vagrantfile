# -*- mode: ruby -*-
# vi: set ft=ruby :

# SLURM集群Vagrant配置 - 使用QEMU/KVM
Vagrant.configure("2") do |config|
  # 通用配置
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = ">= 4.3.0"
  
  # 禁用自动更新
  config.vm.box_check_update = false
  
  # 网络配置
  config.vm.network "private_network", type: "dhcp"
  
  # 共享文件夹
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # QEMU/KVM配置
  config.vm.provider "libvirt" do |vb|
    vb.memory = 1024
    vb.cpus = 2
    vb.disk_bus = "virtio"
    vb.nic_model_type = "virtio"
    vb.graphics_type = "none"
    vb.video_type = "none"
    vb.channel :type => "unix", :target_name => "org.qemu.guest_agent.0", :target_type => "virtio", :name => "org.qemu.guest_agent.0"
  end
  
  # SLURM控制器节点
  config.vm.define "slurmctld" do |slurmctld|
    slurmctld.vm.hostname = "slurmctld"
    slurmctld.vm.network "private_network", ip: "192.168.56.10"
    
    slurmctld.vm.provider "libvirt" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.name = "slurmctld"
    end
    
    # 端口转发
    slurmctld.vm.network "forwarded_port", guest: 22, host: 2210, id: "ssh"
    slurmctld.vm.network "forwarded_port", guest: 6817, host: 6817, id: "slurmctld"
    slurmctld.vm.network "forwarded_port", guest: 6818, host: 6818, id: "slurmd"
    slurmctld.vm.network "forwarded_port", guest: 6819, host: 6819, id: "slurmdbd"
    slurmctld.vm.network "forwarded_port", guest: 6820, host: 6820, id: "slurmrestd"
    
    # 共享文件夹
    slurmctld.vm.synced_folder ".", "/vagrant"
    
    # 配置脚本
    slurmctld.vm.provision "shell", path: "scripts/setup-slurmctld.sh"
  end
  
  # 计算节点1
  config.vm.define "compute1" do |compute1|
    compute1.vm.hostname = "compute1"
    compute1.vm.network "private_network", ip: "192.168.56.11"
    
    compute1.vm.provider "libvirt" do |vb|
      vb.memory = 1024
      vb.cpus = 2
      vb.name = "compute1"
    end
    
    # 端口转发
    compute1.vm.network "forwarded_port", guest: 22, host: 2211, id: "ssh"
    
    # 共享文件夹
    compute1.vm.synced_folder ".", "/vagrant"
    
    # 配置脚本
    compute1.vm.provision "shell", path: "scripts/setup-compute.sh"
  end
  
  # 计算节点2
  config.vm.define "compute2" do |compute2|
    compute2.vm.hostname = "compute2"
    compute2.vm.network "private_network", ip: "192.168.56.12"
    
    compute2.vm.provider "libvirt" do |vb|
      vb.memory = 1024
      vb.cpus = 2
      vb.name = "compute2"
    end
    
    # 端口转发
    compute2.vm.network "forwarded_port", guest: 22, host: 2212, id: "ssh"
    
    # 共享文件夹
    compute2.vm.synced_folder ".", "/vagrant"
    
    # 配置脚本
    compute2.vm.provision "shell", path: "scripts/setup-compute.sh"
  end
  
  # 登录节点
  config.vm.define "login" do |login|
    login.vm.hostname = "login"
    login.vm.network "private_network", ip: "192.168.56.13"
    
    login.vm.provider "libvirt" do |vb|
      vb.memory = 1024
      vb.cpus = 1
      vb.name = "login"
    end
    
    # 端口转发
    login.vm.network "forwarded_port", guest: 22, host: 2213, id: "ssh"
    
    # 共享文件夹
    login.vm.synced_folder ".", "/vagrant"
    
    # 配置脚本
    login.vm.provision "shell", path: "scripts/setup-login.sh"
  end
end
