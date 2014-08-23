#!/usr/bin/env ruby

require "colorize"
require './control.rb'

tor = Tor.new("127.0.0.1", 9051)
tor.authenticate

loop do
    puts "\e[H\e[2J"
    puts "==== Circuit Status ====".red
    circuits = tor.circuit_status
    circuits.each do |k, v|
        STDOUT.write "Circuit #{k}: ".blue
        v.each do |finger_print|
            descr = tor.network_status finger_print
            STDOUT.write "#{descr['nickname'].yellow}##{descr['ip'].green}##{descr['country_code'].cyan} "
        end
        puts
    end
    sleep 5
end
