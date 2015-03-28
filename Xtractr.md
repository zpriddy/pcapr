# Introduction #

http://www.pcapr.net/xtractr is a collaborative cloud app for network forensics and troubleshooting. It can index, search, extract and report on large packet captures. **xtractr** uses [tshark](http://www.wireshark.org) to parse the packets and then uses that information to enable contextual search and reporting using map/reduce. You can read more about this in our blogs:

  * [Announcing xtractr](http://labs.mudynamics.com/2010/02/21/announcing-xtractr-unleash-the-power-of-packets/)
  * [Using Map/Reduce for Network Forensics](http://labs.mudynamics.com/2010/03/08/using-mapreduce-for-network-forensics-and-troubleshooting/)

Also see [xtractr query language](XtractrSearch.md) for more information.

# Ruby API #
**xtractr** is fully restful and we are happy to release Ruby bindings for interacting with the **xtractr** server. Please review the [rdoc documentation](http://pcapr.googlecode.com/svn/trunk/xtractr/doc/index.html) for the methods/classes and how best to chain them together.

To get started:

```
 $ svn checkout http://pcapr.googlecode.com/svn/trunk/xtractr xtractr
 $ gem build xtractr.gemspec
 $ gem install xtractr
```

The Ruby API comes with full rdoc support to introduce you to the various objects in the xtractr index and how to go about chaining them to do interactive network forensics. Assuming you are running the xtractr server, you can now use IRB to do all sorts of cool searches and reports:

```
  $ irb -rirb/completion -rmu/xtractr
  irb> xtractr = Mu::Xtractr.new
```

Here are some things you can do with the xtractr Ruby API:

### Top DNS queries ###
We first pull out all DNS flows and then map/reduce the unique values of
**dns.qry.name** field.

```
xtractr.flows('flow.service:DNS').values('dns.qry.name')
```

### Services used by the top talker (based on bytes sent/received) ###
We first sum the total number of bytes using the src address as the key. The sum function returns the matches sorted by the #bytes. We then use the first object (the top talker) to in turn map/reduce the unique list of services supported by it.

```
xtractr.flows.sum('flow.src', 'flow.bytes').first.count('flow.service')
```

### Trend analysis of fields and terms ###
For each HTTP field, we look for terms that contain NOP slide (buffer overflow).

```
xtractr.fields(/^http/).select { |field| not field.terms(/AAAAAA/i).empty? }
```

### Identify hosts that performed TCP port scans ###
We look for TCP flows (flow.proto:6) that don't have any logical messages in them. In others just a SYN/SYN\_ACK/RST or SYN/RST.

```
xtractr.flows('flow.proto:6 flow.cmsgs:0 flow.smsgs:0').count('flow.src')
```

### Identify DNS queries that timed out (no response) ###
We look for DNS flows that have no messages from the server and then map/reduce those flows to return a list of dns queries.

```
xtractr.flows('flow.service:DNS flow.smsgs:0').count('dns.qry.name')
```

### Extract images from HTTP streams ###
We iterate over all HTTP flows from a given server with the given URL, extract the stream and save the resulting message to separate files.

```
xtractr.flows('flow.service:http favicon.ico').each do |flow|
    flow.contents.each do |content|
        content.save
    end
end
```

### Find URLs that are taking too long ###
Since during the indexing process, **xtractr** calculated the duration of each flow, this one’s pretty easy. We first get a collection of flows that lasted for more than a second and then map/reduce the URI within those flows.

```
xtractr.flows('flow.proto:HTTP flow.duration:>1').count('http.request.uri')
```