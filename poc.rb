require 'droplet_kit'
require 'pry'
require 'net/ssh'

class DropletUpdater
  def initialize(username:, password:, token:)
    @username = username
    @password = password
    @token = token
  end

  def update
    droplets = digital_ocean_droplets

    puts "Got #{droplets.count} droplets"

    binding.pry

    droplets.each do |droplet|
      puts "#{droplet.public_ip}\t\t#{droplet.name}"

      begin
        Net::SSH.start(droplet.public_ip, @username,
                       password: @password,
                       auth_methods: [ 'password' ],
                       number_of_password_prompts: 0) do |ssh|
          output = ssh.exec!('hostname')
          puts output
        end
      rescue
        puts 'FAILED'
      end
      puts '=========='
    end
  end

  private

  def droplet_kit_client
    @client = @client || DropletKit::Client.new(access_token: @token)
  end

  def digital_ocean_droplets
    client = droplet_kit_client
    @droplets = @droplets || client.droplets.all
  end
end

puts 'Creating updater'
droplet_updater = DropletUpdater.new(username: '***', password: '***', token: '***')
puts 'Calling update'
droplet_updater.update
puts 'Done'