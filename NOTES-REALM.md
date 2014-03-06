# Ironfan Realms

Realms in Ironfan are designed to provide us with a logical grouping for clusters (in a similar way
that clusters provide a logical grouping of facets).

## Scope

Following the Principle of Least Surprise, it would make sense that attributes declared in the realm scope,
apply to all clusters unless overridden. The same should go for roles, environment, cloud, and plugins.

```ruby
Ironfan.realm(:foo) do
  environment :dev
 
  role        :rick

  cluster(:bar) do

    role      :over

    facet(:baz) do
      environment :prod
    end

    facet(:qix) do
      role    :out
    end
  end
end

baz_facet = Ironfan.realm(:foo).cluster(:bar).facet(:baz)
baz_facet.environment.should eq(:prod)
baz_facet.run_list.should include_roles(:rick, :over)

qix_facet = Ironfan.realm(:foo).cluster(:bar).facet(:qix)
qix_facet.environment.should eq(:dev)
qix_facet.run_list.should include_roles(:rick, :over, :out)
```

You can also assign realms from within a cluster definition using the method `:realm_name`.
This value defaults to the environment.

```ruby
Ironfan.cluster(:jib) do

   environment :dev

   realm_name  :yo		      
		      
end

Ironfan.cluster(:jab) do

   environment :dev

end

jib_cluster = Ironfan.cluster(:jib)
jib_cluster.realm_name.should eq(:yo)

jab_cluster = Ironfan.cluster(:jab)
jab_cluster.realm_name.should eq(:dev)
```

## Security Groups

Currently, Ironfan creates default security groups for clusters and cluster-facets and authorizes clusters
to allow communication within itself. Because there may be cases where a particular cluster definition may
show up in more than one realm, this behavior will have to be extended to include the realm name as well.
Something that *wont'* be necessary is creating a realm only security group. This is partly because the need
to open access to entire realms *seems* unlikely, and partly because there is a VPC security group limitation
of five per machine.

```
Ironfan.realm(:cybertron) do

  cluster(:autobot) do
    facet(:ratchet) do
      instances 1
    end

    facet(:bumblebee) do
      instances 1
    end
  end

  cluster(:decepticon) do
    facet(:shockwave) do
      instances 1
    end

    facet(:starscream) do
      instances 1
    end
  end
end

bumblebee_facet = Ironfan.realm(:cybertron).cluster(:autobot).facet(:bumblebee)
bumblebee_facet.security_groups should eq(%w[ systemwide cybertron-autobot cybertron-autobot-bumblebee ])

shockwave_facet = Ironfan.realm(:cybertron).cluster(:decepticon).facet(:shockwave)
starscream_facet = Ironfan.realm(:cybertron).cluster(:decepticon).facet(:starscream)

shockwave_facet.machine.should have_access_to(starscream_facet.machine)
shockwave_facet.machine.should_not have_access_to(bumblebee_facet.machine)
```

## Knife Commands

Because of the possibility of cluster names not being unique across realms, the cluster commands will now have to be scoped
by realm as well. This does have a nice side effect of allowing realms to be issued commands as a collective.

By making the knife command explicitly call out the realm, only that realm file will be loaded (again to mitigate
potential collisions in cluster definitions shared across realms), then all cluster files will be loaded.

```bash
knife cluster show p1-control-vcd
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+
| Name             | Chef? | State   | Flavor   | AZ         | Env         | MachineID  | Public IP   | Private IP   | Created On |
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+
| p1-control-vcd-0 | yes   | running | m1.large | us-east-1d | development | i-1ba48935 | 23.20.69.99 | 10.137.18.89 | 2014-02-26 |
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+

knife cluster show p1-control
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+
| Name             | Chef? | State   | Flavor   | AZ         | Env         | MachineID  | Public IP   | Private IP   | Created On |
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+
| p1-control-vcd-0 | yes   | running | m1.large | us-east-1d | development | i-1cd09387 | 69.14.23.44 | 10.114.10.12 | 2014-02-26 |
| p1-control-zbx-0 | yes   | running | m1.large | us-east-1d | development | i-1ba48935 | 23.20.69.99 | 10.137.18.89 | 2014-02-26 |
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+

knife cluster show p1
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+
| Name             | Chef? | State   | Flavor   | AZ         | Env         | MachineID  | Public IP   | Private IP   | Created On |
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+
| p1-kfk-broker-0  | yes   | running | m1.large | us-east-1d | development | i-1io37214 | 52.31.45.9  | 10.88.54.36  | 2014-02-26 |
| p1-kfk-broker-0  | yes   | running | m1.large | us-east-1d | development | i-1ws75110 | 56.90.76.10 | 10.121.27.64 | 2014-02-26 |
| p1-control-vcd-0 | yes   | running | m1.large | us-east-1d | development | i-1cd09387 | 69.14.23.44 | 10.114.10.12 | 2014-02-26 |
| p1-control-zbx-0 | yes   | running | m1.large | us-east-1d | development | i-1ba48935 | 23.20.69.99 | 10.137.18.89 | 2014-02-26 |
+------------------+-------+---------+----------+------------+-------------+------------+-------------+--------------+------------+
```

## Announce/Discovery

When announcing and discovering using silverware, realms will need to be properly taken into account.
Nothing much should change for announcements; you will still announce the system-subsystem pair and the realm
will be provided from the node itself. You will not be able to announce outside of your realm or cluster. Discovery remains
unchanged for the most part as well. Discover with system-subsystem pairs, and it will, by default look in your cluster first,
then in your realm. This behavior can be overridden with options.

```ruby
node['new-phyrexia-sphere-0'].announce(:storm, :master)
# {
#   announces: {
#     storm: {
#       master: {
#         cluster: 'phyrexia',
#         realm:   'new'
#       }
#     }
#   }
# }

storm_master = node['new-benalia-clan-0'].discover(:storm, :master)
storm_master.name.should eq('new-phyrexia-sphere-0')

storm_master = node['alara-bant-sigil-0'].discover(:storm, :master)
storm_master.should be_nil

storm_master = node['alara-bant-sigil-0'].discover(:storm, :master, realm: 'new')
storm_master.name.should eq('new-phyrexia-sphere-0')
```