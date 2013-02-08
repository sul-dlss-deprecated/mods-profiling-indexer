To set up:
------
1.  create a yml config file for your collection going to a Solr index.  

See  config/bnf-images.yml for an example.

You will want to copy that file and change the following settings:
1. coll_fld_val
2. log_name
3. default_set
4. blacklist or whitelist if you are using them

I suggest you use sul-solr-test-a/solr/mods_profiler  as your Solr index, as the number of possible fields required Chris Beer to tweak a tomcat parameter.


To run:
------
(bundle install)

 ./bin/indexer config/(your coll).yml

I suggest you run it on harvestdor-dev, as it is already set up to be able to harvest from the DOR OAI provider and to write to the sul-solr-test index.


To view results:
-------------
  https://sul-solr-test-a/solr/mods_profiler/select?fq=collection:(yer_coll_fld_val)&rows=0
  https://sul-solr-test-a/solr/mods_profiler/select?fq=collection:bnf_images&rows=0

To view more than 20 or 30 facet values

  https://sul-solr-test-a/solr/mods_profiler/select?fq=collection:(yer_coll_fld_val)&rows=0&facet.limit=50
  https://sul-solr-test-a/solr/mods_profiler/select?fq=collection:bnf_images&rows=0&facet.limit=50

To view all the values for a particular facet
  https://sul-solr-test-a/solr/mods_profiler/select?fq=collection:(yer_coll_fld_val)&rows=0&facet.limit=-1&facet.field=(field_name)
  https://sul-solr-test-a/solr/mods_profiler/select?fq=collection:bnf_images&rows=0&facet.limit=-1&facet.field=subject_name_namePart_sim
  
