# This is a very simple recipy to perform a weekly backup of some hbase tables
# using the "hadoop jar hbase.jar export" command. 

include_recipe "hbase"


template "/etc/cron.d/weekly/backup_hbase_tables" do
  source "backup_hbase_tables.rb.erb"
  mode "0744"
  variables {
    :backup_tables   => node[:hbase][:weekly_backup_tables]
    :backup_location => node[:hbase][:backup_location]
  }
end

