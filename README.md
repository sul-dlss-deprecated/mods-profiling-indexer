[![Build Status](https://travis-ci.org/sul-dlss/mods-profiling-indexer.svg)](https://travis-ci.org/sul-dlss/mods-profiling-indexer) [![Dependency Status](https://gemnasium.com/sul-dlss/mods-profiling-indexer.svg)](https://gemnasium.com/sul-dlss/mods-profiling-indexer)

Prereqs:
------
1. ruby
2. bundler gem installed

To set up locally:
------
1. ```$ git clone git@github.com:sul-dlss/mods-profiling-indexer.git```
2. ```$ bundle```

To deploy:
------
1. perform local setup
2. ```$ cap dev deploy```

Set up config for a collection:
------
This must live in deployed ```shared/config/collections``` folder.

1.  create a yml config file for your collection to be profiled.

See  ```spec/config/feigenbaum.yml``` for an example.

I suggest you use
    sul-solr mods_profiler
as your Solr index, as the number of possible fields required Chris Beer to tweak a tomcat parameter.

To run:
------
Run from deployed instance, as that box is already set up to be able to talk to DOR Fetcher service and to SUL Solr indexes.

From deployed ```current``` directory:

1. ```$ ./bin/indexer --help```
2. ```$ ./bin/indexer   will show the possible collections```
3. ```$ ./bin/indexer -c [name of .yml file in config/collections dir)]```


To view results:
-------------
  https://solr.baseurl.org/select?fq=collection:(yer_coll_fld_val)&rows=0
  https://solr.baseurl.org/select?fq=collection:bnf_images&rows=0

To view more than 20 or 30 facet values

  https://solr.baseurl.org/select?fq=collection:(yer_coll_fld_val)&rows=0&facet.limit=50
  https://solr.baseurl.org/select?fq=collection:bnf_images&rows=0&facet.limit=50

To view all the values for a particular facet
  https://solr.baseurl.org/select?fq=collection:(yer_coll_fld_val)&rows=0&facet.limit=-1&facet.field=(field_name)
  https://solr.baseurl.org/select?fq=collection:bnf_images&rows=0&facet.limit=-1&facet.field=subject_name_namePart_sim

