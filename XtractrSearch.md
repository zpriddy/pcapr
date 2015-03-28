# xtractr query language #

**xtractr** uses [Ferret](http://www.davebalmain.com/), in combination with SQLite to store all the data extracted from the pcaps. In some cases Ferret query strings are mapped to SQL statements internally so that the externally visible language is always the powerful query language. While you can check the Ferret documentation for the exact language specification, we'll mostly talk about how it applies to **xtractr** here.

### Fields and Terms ###
For the packets, xtractr effectively builds an inverted index (terms.db on the file system). Each value for the field (like ip.ttl or http.user.agent) contains a set of tokenized _terms_ which then map to which packet of which pcap contained that term. So the basis for querying are fields and terms. In addition to all the tshark fields, xtractr adds its own which are documented here.

### Packet fields ###
**xtractr** stores most of the tshark fields into the Ferret index. In addition here are the packet fields created by xtractr:

  * `pkt.id` - the unique ID of the packet
  * `pkt.pcap` - the unique ID of the pcap in which this packet was found
  * `pkt.flow` - the optional flow to which this packet belongs
  * `pkt.first` - true if this is the first packet in the flow
  * `pkt.dir` - 0 if this packet was sent by the client or 1 if it was sent by the server
  * `pkt.time` - the relative timestamp of this packet
  * `pkt.offset` - the file offset of the packet within its pcap
  * `pkt.length` - the length of the packet
  * `pkt.src` - the source address of the packet
  * `pkt.dst` - the destination address of the packet
  * `pkt.service` - the service of the packet (HTTP, DNS, SIP/SDP, etc)
  * `pkt.title` - the summary title of the packet

All searches on packets can include both the `pkt.*` fields in addition to the various tshark fields.

### Flow fields ###
**xtractr** does flow classification (IP and above) during the indexing process and groups logical sets of packets into conversations or flows. Here are the flow fields created by xtractr:

  * `flow.id` - the unique ID of the flow
  * `flow.time` - the timestamp of the first packet of the flow
  * `flow.duration` - the time difference of the first and last packets in the flow
  * `flow.src` - the source address of the flow
  * `flow.dst` - the destination address of the flow
  * `flow.sport` - the source port of the flow
  * `flow.dport` - the destination port of the flow
  * `flow.proto` - the IP protocol of the flow
  * `flow.service` - the service of the flow (HTTP, DNS, etc)
  * `flow.packets` - the number of packets in this flow
  * `flow.bytes` - sum of all the packet lengths in the flow
  * `flow.cmsgs` - the number of logical requests sent by the client
  * `flow.smsgs` - the number of logical responses sent by the server
  * `flow.title` - normally the title of the first packet of the flow
  * `flow.label` - user-defined labels associated with the flow

Currently searches on flows cannot include the packet and tshark fields, though that's something we are looking into.

## Searching ##
You can read about the syntactic part of searches in the Ferret [documentation](http://ferret.davebalmain.com/api/classes/Ferret/QueryParser.html) which we will mostly adopt here contextualizing it to xtractr. There are some characters in the query string that need to be escaped. These are:

```
 :, (, ), [, ], {, }, !, +, ", ~, ^, -, |, <, >, =, *, ?, \
```

### Term Query ###
This the most basic query of all and can look as simple as this:

```
get http index.html
```

By default xtractr searches for these unqualified (more on this below) terms in the `title` and `service` fields of packets/flows. In other words, the above query can we rewritten as follows, while searching for packets:

```
pkt.title|pkt.service:(get AND http AND index.html)
```

### Field Query ###
Field queries contextualize the terms into one or more specific fields. These queries usually prefix the term that's being searched for with one or more fields:

```
http.user.agent:mozilla
pkt.src:192.168.1.1
```

### Boolean Query ###
By default xtractr AND's the sub-queries, but you can explicitly specify an OR criteria. In order to search for packets that contain either Firefox or Safari, you would do this:

```
http.user.agent:(Firefox || Safari)
```

### Range Query ###
While range queries apply to integer and timestamp fields, you could use them for string fields as well. The most common use case for using ranges are for timestamps. To select all HTTP flows with a duration of more than 5 minutes, the effective query will be:

```
flow.service:HTTP flow.duration:>300
```

You can also do time slices with the range query. In the example below, we are selecting all DNS or HTTP flows in the first five minutes of the index:

```
flow.service(HTTP || DNS) flow.time:[1 300]
```

### Wildcard Query ###
This is very useful for prefix searches and most commonly used for subnets and the like. To find all DNS flows from the 192.168/16 subnet going to 10.1.2.3, the following query will work:

```
flow.service:DNS flow.src:192.168.* flow.dst:10.1.2.3
```