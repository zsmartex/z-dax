require 'excon'
require 'uri'

class DockerAPI
  attr_reader :url, :options

  def initialize
    uri = URI.parse("unix:///var/run/docker.sock")
    @url, @options = 'unix:///', {:socket => uri.path}
  end

  def connection
    Excon.new(url, options)
  end

  def send_request(url)
    response = connection.get(:path => url)
    response.status == 200
  end
end
