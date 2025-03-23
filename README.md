# Forcing apps to fallback to TCP

## Intro

The UDP protocol is more suitable for some applications where getting a lower
latency is more important than loosing some packets. Yet, there are some reasons
to force some applications to fallback to TCP in order to benefit from more
bandwidth when multiple paths can be combined thanks to a TCP-to-MPTCP proxy for
example.

## UDP traffic

There are a few typical use-cases where applications use UDP instead of TCP.

Some of these applications don't require a lot of bandwidth. They typically work
best with one low latency and stable link, e.g. VoIP, games, DNS, etc. In this
case, with multiple paths available, it is better to select a single path, the
most stable and low latency one.

Some others apps might work better when more bandwidth is available, and they
might be OK with a slightly increased delay, e.g. video conferencing (VC). VC
apps are particular, because they use different techniques to provide the same
content adapted to different profiles, e.g. scalable video coding (SVC) and even
TCP-friendly congestion control algorithms. VC can usually easily fallback to
TCP and continue to provide the content in a way that can be transparent to
their users.

There are also two other main reasons to use UDP: for VPN applications, and
protocols like QUIC acting like TCP, but using UDP not to be intercepted by
middleboxes. It might be interesting to get access to more bandwidth in this
case, and fallback to TCP to benefit from a TCP-to-MPTCP proxy.

## Forcing apps to fallback to TCP

Apps supporting a fallback to TCP will do so when UDP is blocked.

The quickest way to tell an app that UDP is blocked is to generate an ICMP
dest-unreach packet in reply to a UDP one. Netfilter will do that by default for
rules using the `REJECT` target.

When a fallback is supported, it is better to do so to use a TCP-to-MPTCP proxy
instead of transporting the UDP traffic in a TCP tunnel, because the end clients
and servers will know that TCP is being used. They will then adapt their
behaviour for the TCP protocol, resulting in a better user experience.

Note that in case of TCP-to-MPTCP proxy that is going to change the source IP
seen by the end server, it is recommended to tunnel the UDP traffic to the same
server not to have UDP and TCP using different traffic. The DNS traffic doesn't
necessarily need to be tunnelled.

## Video conferencing

Because not all VC can properly support a fallback to TCP, it is recommended to
do that for only a selection of those services.

Major VC services provide a list of IPs and ports used by the service, e.g.

- [Microsoft Teams](https://learn.microsoft.com/en-us/microsoft-365/enterprise/urls-and-ip-address-ranges?view=o365-worldwide#microsoft-teams)
- [Zoom](https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0060548)
- [Google Meet](https://support.google.com/a/answer/1279090?hl=en#IP_ranges)

IP sets (type: `hash:net,port`, match: `dst,dst`) should be used to optimise the
matching, see `vc.list` file.

Note: because these IPs and ports can change, it is important to have a way to
easily update them, i.e. remotely.

## VPN

Same here, not all VPN services properly support a fallback to TCP. Plus, using
TCP might affect performances due to the [TCP Meltdown
problem](https://en.wikipedia.org/wiki/Tunneling_protocol#TCP_meltdown_problem).
A "simple" way to minimise this problem is to tell the inner TCP connections not
to retransmit too aggressively (e.g. increasing `rto_min`), but that means
controlling it, which might not be possible when using a transparent proxy.

Because of the number of VPN services, it is recommended to deal with this case
one by one rather than risking breaking connections. An alternative is to proxy
UDP packets in a TCP tunnel, but the performances can be badly affected
depending on the network conditions, e.g. lossy and unstable networks.

Matching this traffic can be done by looking at destination IPs and port, or per
protocol, e.g. DTLS.

## QUIC

Apps and services using QUIC should always support a fallback to TCP. QUIC is
using UDP on port 443, but they are not the only ones to use this port. It is
then recommended to identify QUIC. It should be possible to do that by looking
at the first byte of the packet payload: it should be between 192 and 255
according to RFC 9443.

The `cbpf_quic.sh -4|-6` script generates cBPF code to match QUIC code, e.g.

```shell
iptables  -A OUTPUT -p udp --dport 443 -m bpf --bytecode "$(./cbpf_quic.sh -4)" -j REJECT
ip6tables -A OUTPUT -p udp --dport 443 -m bpf --bytecode "$(./cbpf_quic.sh -6)" -j REJECT
```
