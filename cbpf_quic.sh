#!/bin/bash
# For UDP traffic on port 443

# Instructions: https://kernel.org/doc/Documentation/networking/filter.txt

v4() {
	echo "ldb [0]"          # First byte: version (4) + IHL (4)
	echo "and #0x0f"        # Only IHL
	echo "lsh #2"           # IP payload is at "IHL >> 2"
	echo "st M[0]"          # M[0]: offset of IPv4 payload
}

v6() {
	echo "ldb [6]"          # Next header type
	echo "jne #17, fail"    # Fail if not UDP -- TODO: support ext headers
	echo "ld #40"           # header: 40 bytes
	echo "st M[0]"          # M[0]: offset of IPv6 payload
}

quic() {
	echo "ldx M[0]"         # UDP
	echo "ldh [x + 4]"      # packet length
	echo "jlt #1208, fail"  # Not QUIC if UDP (payload + hdr) < (1200 + 8), RFC 9000 §8.1
	echo "ldb [x + 8]"      # First byte of UDP payload is after UDP header (8B)
	echo "jge #192, quic"   # QUIC if in 192:255 range, RFC 9443
	# Note: for DTLS, it should be in 20:63 range, RFC 9443
	echo "fail: ret #0"     # 0: Not QUIC
	echo "quic: ret #1"     # 1: QUIC
}

(
	if [ "${1}" = "-6" ]; then
		v6
	else
		v4
	fi
	quic
) | bpfc -f xt_bpf -i -
