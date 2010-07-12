

bash "VM overcommit settings" do
  oc_mem = 1
  oc_ratio = 100
  code  "echo #{oc_mem} > /proc/sys/vm/overcommit_memory; echo #{oc_ratio} > /proc/sys/vm/overcommit_ratio"
  only_if{ File.read('/proc/sys/vm/overcommit_memory').chomp.strip != oc_mem.to_s  ||
           File.read('/proc/sys/vm/overcommit_ratio').chomp.strip  != oc_ratio.to_s }
end
