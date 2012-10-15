use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

name 'Graph-Gviz';
all_from 'lib/Graph/Gviz.pm';

requires 'parent';

author_tests('xt');
auto_set_repository();
WriteAll;
