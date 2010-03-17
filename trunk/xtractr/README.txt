# "THE BEER-WARE LICENSE" (Revision 42):
# Mu Dynamics wrote this file. As long as you retain this notice you can do 
# whatever you want with this stuff. If we meet some day, and you think this 
# stuff is worth it, you can buy us a beer in return. 
#
# http://www.pcapr.net
# http://groups.google.com/group/pcapr-forum
# http://labs.mudynamics.com
# http://twitter.com/pcapr

This gem is Ruby front-end to the RESTful API that http://www.pcapr.net/xtractr
provides. We primarily use this for unit testing xtractr's API, but on 
its own this gem provides for a powerful programmable interface into 
xtractr and is a super fast way to extract information out of large pcaps.

[ Getting Started ]
-------------------
First download <b>xtractr</b> from http://www.pcapr.net/xtractr. Follow the
instructions to index your pcap. Finally run xtractr in browse mode and then
you can hang out in IRB poking around flows and packets.

[ Installing the Gem ]
----------------------
$ svn checkout http://pcapr.googlecode.com/svn/trunk/xtractr xtractr
$ gem build xtractr.gemspec
$ gem install xtractr

[ IRB examples ]
----------------
$ irb -rirb/completion -rmu/xtractr
irb> xtractr = Mu::Xtractr.new

Top DNS query names
    
    irb> xtractr.flows('flow.service:DNS').values('dns.qry.name')
    
Services used by the top talker (based on bytes sent/received)

    irb> xtractr.flows.sum('flow.src', 'flow.bytes').first.count('flow.service')
    
Generating #new pcaps based on search criteria

    irb> xtractr.packets.count('http.request.method').each { |c| c.packets.save("#{c.value}.pcap") }
