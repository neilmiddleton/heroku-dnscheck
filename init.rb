require "heroku/command/base"
require 'json'
require 'net/http'

module DnsChecker

  def check_domain(domain)
    return if domain["domain"].match /.*.heroku(app).com/
    return if domain["domain"][0] == "*"
    res = Net::HTTP.get_response check_url(domain)
    parse_results JSON.parse(res.body)
  end

  def check_url(domain)
    URI("http://dnschecker.herokuapp.com/#{domain["domain"]}")
  end

  def parse_results(data)
    display("--- #{data["domain"]}")
    if data["state"] == "green"
      display("OK\n\n")
    elsif data["state"] == "amber"
      display("#{data["comments"]}\n\n")
    else
      display("WARNING - #{data["comments"]}\n\n")
    end
  end
end

class Heroku::Command::Domains < Heroku::Command::Base
  include DnsChecker

  # domains:check
  #
  # check domains are configured correctly for heroku
  #
  def check
    validate_arguments!
    domains = api.get_domains(app).body
    if domains.length > 0
      styled_header("Checking #{app} domains...\n\n")
      domains.collect{|d| check_domain(d) }
    else
      display("#{app} has no domain names.")
    end
  end

end
