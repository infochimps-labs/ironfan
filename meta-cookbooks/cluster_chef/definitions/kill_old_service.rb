
define(:kill_old_service,
  :script       => nil
  ) do
  params[:script] ||= "/etc/init.d/#{params[:name]}"

  # cheating: don't bother if the script isn't there
  if (File.exists?(params[:script]))

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

    file(params[:script]) do
      action :delete
    end
  end
end
