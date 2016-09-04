# domain-inventory
Domain analytics tool useful for hosting companies who are doing migrations and 
need a quick overview of which nameservers a domain is using and which IP the 
A- or AAAA- records are pointing to.

## example-usage

```
./domain-inventory.sh -d domains.list
[Cleanup] Sorted domains.list
Scanning 4 domains for NS records...
Nameserver distribution:
 1 NS/foo.domainlist
 2 NS/bar.domainlist
 3 total
Resolving domains    : 3
Non-resolving domains: 1
Checksum Ok!
```

* The NS directory now contains:
   * $nameserver.domainlist which contains a list per nameserver
   * resolving_domains.txt a list of domains that resolved a NS 
   * non_resolving_domains.txt a list of domains that did not resolve
* fetch_$type_result.txt files contain the raw data provided by dig
