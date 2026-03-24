[![Go build](https://github.com/SpComb/go-nsupdate/actions/workflows/build.yml/badge.svg)](https://github.com/SpComb/go-nsupdate/actions/workflows/build.yml)

# go-nsupdate
Update dynamic DNS records from netlink.

`go-nsupdate` reads interface addresses from netlink, updating on `ip link up/down` and `ip addr add/del` events.

The set of active interface IPv4/IPv6 addresses is used to send DNS `UPDATE` requests to the primary NS for a DNS zone.

The DNS update requests are retried in the background (XXX: currently blocks for 10s on each query attempt).

## Install

    go get github.com/SpComb/go-nsupdate

## Usage

	Usage:
	  go-nsupdate [OPTIONS] [Name]

	Application Options:
	  -v, --verbose
		  --watch                                           Watch for interface changes
	  -i, --interface=IFACE                                 Use address from interface
		  --interface-family=ipv4|ipv6|all                  Limit to interface addreses of given family
		  --server=HOST[:PORT]                              Server for UPDATE query, default is discovered from zone SOA
		  --timeout=DURATION                                Timeout for sever queries (default: 10s)
		  --retry=DURATION                                  Retry interval, increased for each retry attempt (default: 30s)
		  --tsig-name=FQDN
		  --tsig-secret=BASE-64                             base64-encoded shared TSIG secret key [$TSIG_SECRET]
		  --tsig-algorithm=hmac-{md5,sha1,sha256,sha512}
		  --zone=FQDN                                       Zone to update, default is derived from name
		  --ttl=DURATION                                    TTL for updated records (default: 60s)

	Help Options:
	  -h, --help                                            Show this help message

	Arguments:
	  Name:                                                 DNS Name to update

## Docker

Use the GitHub Container Registry image built by GitHub Actions with `host` network mode:

    export TSIG_SECRET=...
    docker run --rm --net=host -e TSIG_SECRET ghcr.io/qmsk/go-nsupdate:master --interface=eth0 --tsig-algorithm=hmac-sha256 --watch yzzrt.dyn.example.net

See https://github.com/qmsk/go-nsupdate/pkgs/container/go-nsupdate

## Bind9

Initialize the dynamic zonefile with `SOA` and `NS` records:

```
$TTL 60

@                              SOA   ns0.example.net. hostmaster.example.net. 0 86400 900 1209600 60
@                              NS    ns0.example.net.
```

Generate the TSIG key as a base64-encoded random string:

    pwgen -s 48 1 | base64


Configure a master zone with a dynamic update policy and associated TSIG keys matching the records to update:

```
key "foobar.dyn.example.net" {
  algorithm hmac-sha256;
  secret "...";
};

zone "dyn.example.net" {
  type master;
  file "/var/lib/bind/zones/dyn.example.net";

  allow-query { any; };

  update-policy {
    grant *.dyn.example.net self . A AAAA;
  };
};
```

Configure the referral in the parent zone:

```
ns0     A     ...
        AAAA  ...

dyn     NS    ns0
```
