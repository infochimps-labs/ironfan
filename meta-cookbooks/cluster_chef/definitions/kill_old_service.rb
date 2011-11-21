
define(:kill_old_service,
  :script       => nil,
  ) do
  params[:script] ||= "/etc/init.d/#{params[:name]}"

  service params[:name] do
    action      [:stop, :disable]
    pattern     params[:pattern] if params[:pattern]
    only_if{ File.exists?(params[:script]) }
  end

  ruby_block("stop #{params[:name]}") do
    block{ }
    action      :create
    notifies    :stop, "service[#{params[:name]}]", :immediately
    only_if{ File.exists?(params[:script]) }
  end

  # file(params[:script]) do
  #   action :delete
  # end
end

# # kill apt's service
# bash 'stop old gmetad service' do
#   command %Q{service gmetad stop; true}
#   only_if{ File.exists?('/etc/init.d/gmetad') }
# end
# file('/etc/init.d/gmetad'){ action :delete }

# # kill apt's service
# bash 'stop old ganglia-monitor service' do
#   command %Q{service ganglia-monitor stop; true}
#   only_if{ File.exists?('/etc/init.d/ganglia-monitor') }
# end
