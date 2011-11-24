

Sometimes we want 

* if there are volumes marked for 'mysql-table_data', use that; otherwise, the 'persistent' datastore, if any; else the 'bulk' datastore, if any; else the 'fallback' datastore (which is guaranteed to exist).

* IP addresses (or hostnames):
  - `[:private_ip, :public_ip]`
  - `[:private_ip]`
  - `:primary_ip`
  
* .  
