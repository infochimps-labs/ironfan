%w[
dm-adjust
dm-aggregates
dm-ar-finders
dm-cli
dm-constraints
dm-core
dm-couchdb-adapter
dm-ferret-adapter
dm-is-list
dm-is-nested_set
dm-is-remixable
dm-is-searchable
dm-is-state_machine
dm-is-tree
dm-is-versioned
dm-is-viewable
dm-migrations
dm-more
dm-observer
dm-querizer
dm-rest-adapter
dm-serializer
dm-shorthand
dm-sweatshop
dm-tags
dm-timestamps
dm-types
dm-validations
do_mysql
do_sqlite3
mysql
].each do |pkg|

  gem_package(pkg){ action :install }

end

