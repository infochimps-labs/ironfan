# Creates a file holding a Whenever schedule and runs +whenever+ on
# it, adding it to the crontab.
#
# Running
#
#   schedule "my_app"
#
# will use a template at "my_app.rb.erb" to create the schedule file
# at "/etc/whenever/my_app_schedule.rb".
#
# You can specfiy a different source for the template by passing in
# +source+, a different path for the schedule file with
# +schedule_path+, and a different user with +user+:
#
#   schedule "my_app" do
#     source        "some_other_template.rb.erb"
#     schedule_path "/etc/cron/my_app_schedule.rb"
#     user          "my_app_user"
#   end
define :schedule, :source => nil, :schedule_path => nil, :user => 'root' do
  include_recipe "whenever"

  params[:source]        ||= "#{params[:name]}_schedule.rb.erb"
  params[:schedule_path] ||= File.join('/etc/whenever', "#{params[:name]}_schedule.rb")

  template params[:schedule_path] do
    source params[:source]
    action :create
    group 'admin'
    mode 0774
  end

  # FIXME there is a more Chef-y way to do this
  bash "update crontab for #{params[:name]}" do
    user params[:user]
    code "whenever --update-crontab -f #{params[:schedule_path]}"
  end

end
