use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

name 'Graphviz-DSL';
all_from 'lib/Graphviz/DSL.pm';

requires 'parent';
requires 'File::Which';

author_tests('xt');
auto_set_repository();
WriteAll;
