curl "https://sul-solr-test.stanford.edu/solr/mods_profiler/update?commit=true" -H "Content-Type: application/xml" --data-binary '<delete><query>collection:bnf_images</query></delete>'
