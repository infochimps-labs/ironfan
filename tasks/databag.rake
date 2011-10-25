# in tasks dir

#
# Author:: Alexander Goldstein (<alexg-at-pangeaequity.com>)
# Copyright:: Copyright (c) 2008, 2009 Pangea Ventures, LLC
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'

def knife_client
  return @knife_client if @knife_client

  chef_config_file = File.join(ENV['HOME'], '.chef', 'knife.rb')
  @knife_client = Chef::Knife.new
  @knife_client.config[:config_file] = chef_config_file
  @knife_client.configure_chef
  @knife_client
end

def rest; knife_client.rest end

desc "Dump out data bags"
task :dump_data_bags do
  # TODO: replace with direct REST access
  bags_dir = File.join(TOPDIR, "data_bags")
  Dir.mkdir bags_dir unless File.directory? bags_dir

  bag_ids = JSON.parse %x(knife data bag list --format=json)
  bag_ids.sort.each do |bag_id|
    item_ids = JSON.parse %x(knife data bag show #{bag_id} --format=json)
    items_j = item_ids.map do |item_id|
      %x( knife data bag show #{bag_id} #{item_id} --format=json)
    end
    items = items_j.map {|j| JSON.parse j }
    # TODO: limit number of backups
    fullname = File.join(bags_dir, bag_id) + '.json'
    time_suffix = Time.new.strftime("%Y%m%d_%H%M%S")
    File.rename(fullname, fullname+'.'+time_suffix) if File.exists?(fullname)

    File.open(fullname, 'w') do |out|
      out << JSON.pretty_generate(items)
      out << "\n"
    end
  end
end

# TODO: use DataBag interface
desc "Load data bags"
task :load_data_bags do
  bags_dir = File.join(TOPDIR, "data_bags")

  bag_ids = JSON.parse %x(knife data bag list --format=json)
  files = Dir[ File.join(bags_dir, '*.json') ].map {|f|
    File.basename(f, '.json')
  }

  new_bags          = files - bag_ids
  missing_files     = bag_ids - files
  bag_ids_to_update = files & bag_ids

  new_bags.each do |new_bag_id|
    system "knife data bag create #{new_bag_id} --format=json"
  end

  if ! missing_files.empty? then
    puts "Following bags don't have files to load: %s" %
      missing_files.join(', ')
  end

  bag_ids_to_update.each do |bag_id|
    fullname = File.join(bags_dir, bag_id) + '.json'
    json = File.read(fullname)
    content = JSON.parse json
    raise "array of items expected: #{json}" unless content.is_a?(Array)

    item_hash = content.inject({}) do |h,item|
      raise "item missing id: %s" % JSON.pretty_generate(item) unless
        item['id']
      h[item['id']] = item
      h
    end

    # file_item_ids = content.map{|item| item['id']}
    file_item_ids = item_hash.keys.sort
    item_ids = JSON.parse %x(knife data bag show #{bag_id} --format=json)

    item_ids_with_bad_ids = file_item_ids.select {|item_id| item_id !~ /^\w(\w|[-_])+$/ }
    unless item_ids_with_bad_ids.empty?
      raise "ERROR: item ids have invalid names: %s" % item_ids_with_bad_ids.join(' ')
    end

    ids_to_delete = item_ids - file_item_ids
    ids_to_create = file_item_ids - item_ids
    ids_to_update = item_ids & file_item_ids

    ids_to_update.each do |item_id|
      item_url = "data/#{bag_id}/#{item_id}"

      if item_hash[item_id] == rest.get_rest(item_url) then
        puts "skipping #{item_url}"
      else
        puts "updating #{item_url}"
        rest.put_rest(item_url, item_hash[item_id])
      end
    end
    ids_to_create.each do |item_id|
      puts "creating #{bag_id}/#{item_id}"
      rest.post_rest("data/#{bag_id}", item_hash[item_id])
    end
    ids_to_delete.each do |item_id|
      puts "deleting #{bag_id}/#{item_id}"
      rest.delete_rest("data/#{bag_id}/#{item_id}")
    end
  end
end

