# "THE BEER-WARE LICENSE" (Revision 42):
# Mu Dynamics wrote this file. As long as you retain this notice you can do 
# whatever you want with this stuff. If we meet some day, and you think this 
# stuff is worth it, you can buy us a beer in return. 
#
# http://www.pcapr.net
# http://groups.google.com/group/pcapr-forum
# http://labs.mudynamics.com
# http://twitter.com/pcapr

module Mu
class Xtractr
# = Flow
# Flow represents a single conversation between two hosts. Depending on whether
# it's IP, UDP or TCP, xtractr uses different information from the IP header
# of the packets (src/dst addresses and ports) to logically group them
# together. Each flow also has the duration (difference in the timestamp between
# the first and last packet in the conversation), the total bytes that were
# exchanged as well as the logical messages that were exchanged. For example:
#
# <b>Identify hosts that performed TCP port scans</b>
#
#  xtractr.flows('flow.proto:6 flow.cmsgs:0 flow.smsgs:0').count('flow.src')
#
# <b>Identify DNS queries with no response (possibly timed out)</b>
#
#  xtractr.flows('flow.service:DNS flow.smsgs:0').count('dns.qry.name')
class Flow
    include Enumerable
    
    attr_reader :xtractr # :nodoc:
    
    # The unique ID of the flow.
    attr_reader :id
    
    # The timestamp of the flow, determined by the first packet in the flow.
    attr_reader :time
    
    # The duration of the flow, determined by the first and last packet in the flow.
    attr_reader :duration
    
    # The source host of the flow.
    attr_reader :src
    
    # The destination host of the flow.
    attr_reader :dst
    
    # The IP protocol of the flow.
    attr_reader :proto
    
    # The source port of the flow (if applicable).
    attr_reader :sport
    
    # The destination port of the flow (if applicable).
    attr_reader :dport
    
    # The service of the flow (like DNS or HTTP).
    attr_reader :service
    
    # The title of the flow.
    attr_reader :title
    
    # The total ##packets in the flow.
    attr_reader :packets
    
    # The total ##bytes (request and response) in the flow.
    attr_reader :bytes
    
    # The logical client messages (payloads) in the flow.
    attr_reader :cmsgs
    
    # The logical server messages (payloads) in the flow.
    attr_reader :smsgs
    
    def initialize xtractr, json # :nodoc:
        @xtractr  = xtractr
        @id       = json['id']
        @time     = json['time']
        @duration = json['duration']
        @src      = Host.new xtractr, json['src']
        @dst      = Host.new xtractr, json['dst']
        @proto    = json['proto']
        @sport    = json['sport']
        @dport    = json['dport']
        @service  = Service.new xtractr, json['service']
        @title    = json['title']
        @packets  = json['packets']
        @bytes    = json['bytes']
        @cmsgs    = json['cmsgs']
        @smsgs    = json['smsgs']
        @iterator = Packets.new(xtractr, :q => "pkt.flow:#{id}")
    end
    
    # Iterate over each packet in this flow.
    #  flow.each { |pkt| ... }
    def each(&blk) # :yields: packet
        @iterator.each(&blk)
        return self
    end
    
    # Reassemble the TCP stream for this flow (assuming it's a TCP flow) and
    # return the stream. This is the basis for doing content extraction from
    # packets even if the packets span multiple pcaps.
    #  xtractr.service('HTTP').flows.first.stream
    def stream
        result = xtractr.json "api/flow/#{id}/stream"
        return Stream.new(xtractr, self, result)
    end
    
    # Stich together a pcap made up of all packets containing this flow and
    # save it to the filename. It's possible for the packets to span multiple
    # pcaps, but xtractr makes it seamless.
    #  flow.save("foo.pcap")
    def save filename
        open(filename, "w") do |ios|
            pcap = xtractr.get "api/packets/slice", :q => "pkt.flow:#{id}"
            ios.write pcap
        end
    end
    
    def inspect # :nodoc:
        "#<flow:#{id} #{service.name} #{src.address}:#{sport} > #{dst.address}:#{dport} #{title}"
    end
    
    alias_method :each_packet, :each
end
end # Xtractr
end # Mu
