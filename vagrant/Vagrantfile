# -*- mode: ruby -*-
# vi: set ft=ruby :

# Read config file, if any
require 'yaml'
clousr_config_file = "#{ENV['HOME']}/.clousr/config.yml"
clousr_config = {}
begin
  clousr_config = YAML.load_file clousr_config_file
rescue
  puts "[WARNING]: No clousr config file found @ '#{clousr_config_file}'"
end

# If there are any exports, set them here
clousr_config['exports'].each { |key,val| ENV[key] = val unless ENV.include? key } if clousr_config['exports']

# Load deplyment_mode, from environment first, then file, default if none
if ENV['ENVIRONMENT'] != nil
  deploy_target = ENV['ENVIRONMENT']
  puts "[INFO] Using deploy_target from environment: #{deploy_target}"
elsif clousr_config['environment'] != nil
  deploy_target = clousr_config['environment']
  puts "[INFO] Using deploy_target from config file: #{deploy_target}"
else
  deploy_target = 'qa'
  puts "[INFO] Using default deploy_target: #{deploy_target}"
end

unless ['qa', 'prod'].include? deploy_target
  puts "[ERROR] Invalid deploy_target: #{deploy_target}"
  exit
end

# Because of this, machine names in the CLI need to have the proper prefix:
# vagrant up qa-clousr-rancher_server
deploy_prefix = "#{deploy_target}-"

Vagrant.configure(2) do |config|

  deploy_params = {
    :private_key_path => {
      'prod' =>  '~/.ssh/clousr_prod_keys.pem', 'qa' => '~/.ssh/cluster-keys.pem'
    },
    :keypair_name => {
      'prod' =>  'clousr_prod_keys', 'qa' => 'cluster-keys'
    }
  }

  # Despite the name, final machine ID is deploy_prefix + machine_name
  machines = {
    :rancherserver => {
      :vbox_ip => '192.168.69.2',
      :elastic_ip => nil,
      :associate_public_ip => true,
      :region => 'eu-west-1',
      :ami_id =>  {
        'prod' => 'ami-7abd0209',  # Community Centos 7 image
        'qa' => 'ami-7abd0209'
      },
      :ami_username => {
        'prod' => 'centos', 'qa' => 'centos'
      },
      :ami_size => {
        'prod' => 't2.small', 'qa' => 't2.small'
      },
      :subnet_id => {
        'prod' => 'subnet-3608dd40', 'qa' => 'subnet-134d7464'
      },
      :availability_zone => {
        'prod' => 'eu-west-1a', 'qa' => 'eu-west-1a'
      },
      :ami_security_groups => {
        'prod' => [
          'sg-fc6ac09b', # External access group
          'sg-9745ecf0'  # VPC group
        ],
        'qa' => [
          'sg-fe49099a', # default,
          'sg-16229471', # external access
        ]
      },
      :bootstrap => {:bootstrap_file => "./rancher/server/bootstrap.sh" }
    },
    :rancheragent => {
      :instances => 2, # I do not use this...
      :vbox_ip => '192.168.69.100',
      :elastic_ip => nil,
      :associate_public_ip => true,
      :region => 'eu-west-1',
      :ami_id =>  {
        'prod' => 'ami-7abd0209',  # Community Centos 7 image
        'qa' => 'ami-7abd0209'
      },
      :ami_username => {
        'prod' => 'centos', 'qa' => 'centos'
      },
      :ami_size => {
        'prod' => 't2.small', 'qa' => 't2.small'
      },
      :subnet_id => {
        'prod' => 'subnet-3608dd40', 'qa' => 'subnet-134d7464'
      },
      :availability_zone => {
        'prod' => 'eu-west-1a', 'qa' => 'eu-west-1a'
      },
      :ami_security_groups => {
        'prod' => [
          'sg-fc6ac09b', # External access group
          'sg-9745ecf0'  # VPC group
        ],
        'qa' => [
          'sg-fe49099a', # default,
          'sg-16229471', # external access
        ]
      },
      :bootstrap => {:bootstrap_file => "./rancher/agent/bootstrap.sh" }
    }
  }

  # vagrant-hostmanager global config
  config.hostmanager.enabled = false # so it runs as a provisioner
  config.hostmanager.manage_host = false
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  cached_addresses = {}
  config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
    if cached_addresses[vm.name].nil?
      if vm.ssh_info && vm.ssh_info[:host]
        vm.communicate.execute("hostname -I") do |type, contents|
          cached_addresses[vm.name] = contents.split("\n").first[/(\d+\.\d+\.\d+\.\d+)/, 1]
        end
      end
    end
    cached_addresses[vm.name]
  end

  machines.each do |machine_name, params|

    config.vm.define "#{deploy_prefix}#{machine_name.to_s}".to_sym do |host|

      # vagrant-hostmanager machine-specific:
      # the hostname is already added to the hosts file by the plugin
      host.vm.host_name = "#{deploy_prefix}#{machine_name.to_s}"
      host.vm.provision :hostmanager
      if params[:aliases]
        host.hostmanager.aliases = params[:aliases]
      end

      # Dummy AWS box, add with: vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
      host.vm.box = "dummy"
      host.vm.synced_folder ".", "/vagrant", disabled:true

      host.vm.provider :aws do |aws, override|

        aws.tags = {
          'Name' =>  "#{deploy_prefix}#{machine_name.to_s}"
        }

        # Execute the ./secret_export script to set these
        aws.access_key_id = (ENV['AWS_ACCESS_KEY'] || '')
        aws.secret_access_key = (ENV['AWS_SECRET_KEY'] || '')

        # Required in CentOS/Amazon Linux
        override.ssh.pty = true

        aws.region = params[:region]

        ## WARNING: Until I setup provisioning through a bastion, this needs to be truthy
        aws.associate_public_ip = true # or params[:associate_public_ip]

        aws.private_ip_address = params[:private_ip_address] or nil
        aws.elastic_ip = params[:elastic_ip] or false

        ### FLAVOR DEPENDENT VARIABLES
        # Make sure the AZ matches the subnet !!
        aws.subnet_id = params[:subnet_id][deploy_target]
        aws.availability_zone = params[:availability_zone][deploy_target]
        aws.instance_type = params[:ami_size][deploy_target]
        aws.security_groups = params[:ami_security_groups][deploy_target]

        # Make sure you have the key avaialble in your computer too
        override.ssh.private_key_path = deploy_params[:private_key_path][deploy_target]
        aws.keypair_name = deploy_params[:keypair_name][deploy_target]

        # username usually depends on AMI, be careful
        aws.ami = params[:ami_id][deploy_target]
        override.ssh.username = params[:ami_username][deploy_target]
      end

      host.vm.provider :virtualbox do |vb, override|
        vb.cpus = 1
        vb.memory = 1*1024
        vb.name = params[:name]

        override.vm.box = "centos/7"
        override.vm.network "private_network",  ip: params[:vbox_ip]
        if params[:vbox_guest_port] then
          override.vm.network "forwarded_port",
            guest: params[:vbox_guest_port],
            host: params[:vbox_host_port]
        end
      end

      # AUTOMATIC PROVISIONING
      $ntp_script = <<SCRIPT
      # Install rsyslog and configure remote log sink
      yum install -y rsyslog
      echo 'local0.* @log-collector' > /etc/rsyslog.d/clousr.conf
SCRIPT
      host.vm.provision "shell", privileged: true, inline: $ntp_script

      if params[:bootstrap]
        # Copy files to default location first
        params[:bootstrap][:files].each do |f|
          host.vm.provision "file", source: "#{f}", destination: "/tmp/#{machine_name.to_s}/"
        end if params[:bootstrap][:files]

        # Execute specific bootstrap
        host.vm.provision "file", source: params[:bootstrap][:bootstrap_file], destination: "/tmp/bootstrap.sh"
        host.vm.provision "shell", privileged: true, inline: "bash /tmp/bootstrap.sh #{deploy_target}"
      end
    end
  end

  # Specific machine's config
  config.vm.define "#{deploy_prefix}rancherserver".to_sym do |rancherserver|

    # Export secrets from an off-repo file
    $host_script = <<SCRIPT
    file=`mktemp secrets.XXXX`

    echo '#!/bin/false' >> $file
    echo export rancherserver_ADMIN_PASSWORD=#{clousr_config['rancherserver_admin_password']} >> $file

    sudo chmod a+r $file
    mv $file /tmp/secrets
SCRIPT
    rancherserver.vm.provision "shell", inline: $host_script
  end
end
