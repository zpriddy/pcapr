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
# = Stream
# Represents a logical TCP stream made of messages (potentially spanning
# multiple packets across multiple pcaps). A given message in the stream is
# potentially stitched together from multiple packets. Streams form the basis
# of doing content-analysis with xtractr. xtractr does all the work of
# reassembling the packets and pulling out the appropriate payload from
# each of the packets.
#
#  xtractr.flows('flow.service:http').first.stream.find do |message|
#      m =~ /xml/
#  end
class Stream
    include Enumerable
    
    attr_reader :xtractr # :nodoc
    
    # Return the flow that this stream represents.
    attr_reader :flow
    
    # Return a list of Messages in this stream.
    attr_reader :messages
    
    # = Message
    # Represents a single logical TCP message that has been potentially
    # reassembled from across multiple packets spanning multiple pcaps. Each
    # message contains the stream to which it belongs in addition to whether
    # this message was sent from the client or the server.
    class Message
        # Returns the stream to which this message belongs to.
        attr_reader :stream
        
        # Returns the index within the stream
        attr_reader :index
        
        # Returns the direction of the message (request/response).
        attr_reader :dir
        
        # Returns the actual bytes of the message.
        attr_reader :bytes
        
        def initialize stream, index, dir, bytes # :nodoc:
            @stream = stream
            @index  = index
            @dir    = dir
            @bytes  = bytes
        end
        
        def inspect # :nodoc:
            preview = bytes[0..32]
            preview << "..." if bytes.size > 32
            return "#<message:#{index} flow-#{stream.flow.id} #{preview.inspect}>"
        end
    end
    
    def initialize xtractr, flow, json # :nodoc:
        @xtractr  = xtractr
        @flow     = flow
        @messages = []
        
        json['packets'].each do |pkt|
            bytes = (pkt['b'] || []).map { |b| b.chr }.join('')
            if messages.empty? or messages.last.dir != pkt['d']
                messages << Message.new(self, messages.size, pkt['d'], bytes)
            end
            messages.last.bytes << bytes
        end
    end
    
    # Iterate over each message in this stream
    def each &blk
        messages.each(&blk)
        return self
    end
    
    def inspect # :nodoc:
        return "#<stream:#{flow.id} ##{messages.size} messages>"
    end
    
    alias_method :each_message, :each
end
end # Xtractr
end # Mu
