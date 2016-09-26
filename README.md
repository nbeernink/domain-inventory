# domain-inventory
Domain analytics tool useful for hosting companies who are doing migrations and
need a quick overview of which nameservers a domain is using and which IP the
A- or AAAA- records are pointing to.

## example-usage

```
$ ./domain-inventory -d domains.list -i ips.list
Scanning 21 domains for NS records...

Nameserver distribution:
  1 domains_hosted_by_foo.txt
  1 domains_hosted_by_bar.txt
  1 domains_hosted_by_foobar.txt
 14 domains_hosted_by_example.txt
 17 total

Scanning 17 domains for A records...

==================== Summary ====================

Domains in supplied list: 21

*** NS-record analysis ***
Resolving domains       : 17
Non-resolving domains   : 4

*** A-record analysis ***
Aligned IPV4 domains    : 15
Unaligned IPV4 domains  : 2

Finished! Check your results in: result-2016-09-26
```

## Description for output files
* domains_with_CNAME.txt                                                - a list of domains that use a CNAME to refer to
  another nameserver. This should be fixed as it's not according to RFC
2181 standards (section 10.3)
* domains_hosted_by_foo.txt                                             - a list of domains hosted on that nameserver
* domains_hosted_in_multiple_nameservers.txt                            - domains that are hosted in two
  ore more nameservers.
* domains_resolving.txt                                                 - domains that have resolving nameservers
* domains_non_resolving.txt                                             - domains that didn't resolve
* domains_aligned.txt                                                   - domains that point to an ip in your list
* domains_unaligned.txt                                                 - domains that don't point to an ip in your list
* fetch_$type_result.txt                                                - files contain the raw data provided by dig
