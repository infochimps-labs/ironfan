## cluster composition

Here are some plausible cluster setups:

### Small, simple cluster ("Zaius")

A modest, no-fuss cluster to get started:

* Master node acts as chef server, nfs server, hadoop master (namenode, secondarynamenode and jobtracker), hadoop worker.
* 0-5 worker nodes: nfs client, hadoop worker.
* All nodes are EBS-backed instances, sized large enough to hold the HDFS.
* Use non-spot pricing, but manage costs by starting/stopping instances when not in use. (Set 'ebs_delete_on_termination' to false and 'disable-api-termination' to true)

### Spot-priced cluster with persistent HDFS ("Gibbon")

A many-node cluster that can be spot priced (or frequently launched/terminated); uses persistent EBS volumes for the HDFS.

* A standalone EBS-backed small instance acting as the nfs server. All other nodes are NFS clients.
* A standalone namenode
* A secondarynamenode and jobtracker
* 6-40 spot-priced worker nodes: hadoop worker.
* All nodes are local-backed instances with EBS volumes attached at startup.
* You can shut down the cluster (or tolerate EC2 shutting it down if the spot price spikes) without harm to the HDFS. The NFS home dir lets you develop scripts on a small cluster and only spin up the big cluster for production jobs.
* You can specify any scale of instance depending on whether your job is IO-, CPU- or memory-intensive, and size master and worker nodes independently.

### Tradeoffs of EBS-backed volumes

Be careful of the tradeoffs with EBS-backed volumes.

* _good_: You can start and stop instances -- don't pay for the compute from the end of that hour until you restart.
* _good_: It's way easier to tune up an AMI. (Then again, chef makes much of that unnecessary)
* _good_: You can make the volume survive even if the node is terminated (spot price is exceeded, machine crashes, etc).
* _good_: You can make a persistent HDFS without having to fart around attaching EBS volumes at startup. There are performance tradeoffs, though.
* _bad_: The disk is noticably slower. Make sure to point tempfiles and scratch space to the local drives. (The scripts currently handle most but not all of this).
* _bad_: The root volume counts against your quota for EBS volumes.
* _bad_: Starting more than six or so EBS-backed instances can cause AWS to shit a brick allocating all the volumes.

Refer to the standard setups described above.
