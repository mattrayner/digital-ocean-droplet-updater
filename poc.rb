require 'droplet_kit'
require 'pry'
require 'net/ssh'
require 'filesize'

class DropletUpdater
  def initialize(username:, password:, token:)
    @username = username
    @password = password
    @token = token
  end

  def update
    droplets = digital_ocean_droplets

    puts "Droplets: #{droplets.count}"

    # binding.pry

    responses = []

    droplets.each do |droplet|
      puts "Processing: #{droplet.name} - #{droplet.public_ip}"

      begin
        Net::SSH.start(droplet.public_ip, @username,
                       password: @password,
                       auth_methods: [ 'password' ],
                       number_of_password_prompts: 0) do |ssh|
          output = ssh.exec!('if [ -d "web" ]; then cd web && du -s *; fi;')

          sizes = output.split(/\n/).map{ |line| { site: line.split(/\t/)[1], size: line.split(/\t/)[0] } unless line.include? 'du: cannot access' }.compact

          data_object = {
              droplet: {
                  ip: droplet.public_ip,
                  name: droplet.name
              },
              output: output,
              sizes: sizes
          }

          responses << data_object

        end
      rescue
        puts 'Unable to process'
      end
      puts "Done\n--------"
    end

    puts '========='

    responses.each do |data|
      data[:sizes].each do |size|
        filesize = Filesize.from("#{size[:size]} KB").pretty

        puts "#{size[:site]}\t#{filesize}"
      end
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
