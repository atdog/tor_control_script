#!/usr/bin/env ruby

require "socket"
require "colorize"

class Tor
    attr_accessor :s

    def initialize(ip, port)
        @s = connect(ip, port) 
    end

    def connect(ip, port)
        @s = TCPSocket.open(ip, port)
    end

    def authenticate(password = "")
        password = password.unpack("H*").first
        send("AUTHENTICATE #{password}")
        read
    end

    def circuit_status
        send("GETINFO circuit-status")
        parse_circuit(read)
    end

    def parse_circuit(data)
        output = {}

        circuits = data.split "\r\n"[1]
        circuits.each do |circuit|
            circuit.match(/^(?<circuit_id>\d+)\s+BUILT\s+\$/) do |m|
                finger_prints = []
                circuit.split[2].split(",").each do |longname|
                    finger_prints.push longname[/\$([a-z0-9]{40})/i,1]
                end
                output[m['circuit_id']] = finger_prints
            end
        end
        output
    end

    def network_status(id)
        id.sub!("$","")
        send("GETINFO ns/id/#{id}")
        parse_descr(read)
    end

    def parse_descr(data)
        descr = {}
        data.match(/r (?<nickname>\w+) .* \d+:\d+:\d+ (?<ip>\d+\.\d+\.\d+\.\d+) \d+/) do |m|
            descr['ip'] = m['ip']
            descr['nickname'] = m['nickname']
            descr['country_code'] = get_country m['ip']
        end
        descr
    end

    def get_country(ip)
        send("GETINFO ip-to-country/#{ip}")
        parse_country(read)
    end

    def parse_country(data)
        country_code = ""
        data.match(/\/\d+\.\d+\.\d+\.\d+=(?<country_code>\w{2})/) do |m|
            country_code = m['country_code']
        end
        country_code
    end

    def send(str)
#          puts str.green
        @s.puts str
    end

    def read
        result = ""
        loop do
            str = @s.gets
            result << str
#              puts str.chomp.yellow
            if str.chomp == "250 OK"
                break
            end
        end
        result
    end
end
