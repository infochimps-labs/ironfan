#
execute 'updatedb' do
  command %Q{updatedb}
  creates '/var/lib/mlocate/mlocate.db'
end

