if cluster_ebs_volumes
  cluster_ebs_volumes.each do |conf|
    bash "Wait for ebs volumes to attach" do
      not_if{ File.exists?(conf['device']) }
      code <<EOF
  echo #{conf.to_hash.inspect}:
  i=1
  while true ; do
    sleep 2
    echo -n "$i "
    i=$[$i+1]
    test -e "#{conf['device']}" || continue
    echo "`date` #{conf['device']} mounted for #{conf.to_hash.inspect}" >> /tmp/wait_for_attachment_err.log
    ls -l /dev/sd* >>  /tmp/wait_for_attachment_err.log
    mount          >>  /tmp/wait_for_attachment_err.log
    sleep 5
    break;
  done
  true
EOF
    end
  end

end
