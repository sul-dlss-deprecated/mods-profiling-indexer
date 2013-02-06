# change value below to YOUR collection
curl "https://sul-solr-test.stanford.edu/solr/mods_profiler/update?commit=true" -H "Content-Type: application/xml" --data-binary '<delete><query>collection:yer_coll</query></delete>'
