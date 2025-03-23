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

Apps supporting a fallback to TCP will do so when UDP is blocked. The quickest
way to tell an app that UDP is blocked is to generate an ICMP dest-unreach
packet in reply to a UDP one.

Netfilter will do that by default for rules using the `REJECT` target.
