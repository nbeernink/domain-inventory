# domain-inventory
Domain analytics tool useful for hosting companies who are doing migrations and 
need a quick overview of which nameservers a domain is using and which IP the 
A- or AAAA- records are pointing to.

## example-usage

```
./domain-inventory -d mydomain.list -o my-results-dir
Scanning 500 domains for NS records...
Nameserver distribution:
 200 domains_hosted_by_foo.txt
 300 domains_hosted_by_bar.txt
 500 total
Resolving domains    : 500
Finished! Check your results in: my-results-dir
```

## Description for output files
* domains_hosted_by_foo.txt - a list of domains hosted on that nameserver
* domains_resolving.txt     - domains that have resolving nameservers
* domains_non_resolving.txt - domains that didn't resolve
* domains_aligned.txt	    - domains that point to an ip in your list
* domains_unaligned.txt     - domains that don't point to an ip in your list
* fetch_$type_result.txt    - files contain the raw data provided by dig
