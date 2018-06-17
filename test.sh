perl -Ilib bin/testplan --version 0.001 --prompt t/*.t
perl -I$PWD/lib bin/testd
perl -Ilib `which prove` -PElasticsearch
