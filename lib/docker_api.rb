require 'net/http'
require 'openssl'
require 'uri'

class DockerAPI
  def initialize
    @DEFAULT_OPTIONS = {
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_PEER,
      keep_alive_timeout: 30,
      cert: OpenSSL::X509::Certificate.new(File.read("./config/docker_certs/cert.pem")),
      key: OpenSSL::PKey::RSA.new(File.read("./config/docker_certs/key.pem")),
      ca_file: File.join("./config/docker_certs/", "ca.pem")
    }
  end

  def send_request(url)
    http = Net::HTTP.start("docker.local", 2376, @DEFAULT_OPTIONS)
    response = http.request Net::HTTP::Get.new url

    return response.code.to_i == 200
  end
end