module Ironfan
  module Dsl
    class Volume < Ironfan::Dsl::Builder
      magic     :attachable,            String,   :default => 'ebs'
      magic     :availability_zone,     String
      magic     :create_at_launch,      Whatever, :default => false  # FIXME: Boolean?
      magic     :device,                String
      magic     :formattable,           Whatever, :default => false  # FIXME: Boolean?
      magic     :fstype,                String,   :default => 'xfs'
      magic     :in_raid,               Whatever, :default => false  # FIXME: Boolean?
      magic     :keep,                  Whatever, :default => true   # FIXME: Boolean?
      magic     :mount_dump,            String
      magic     :mount_pass,            String
      magic     :mount_options,         String,   :default => 'defaults,nouuid,noatime'
      magic     :mount_point,           String
      magic     :mountable,             Whatever, :default => true
      magic     :size,                  String
      magic     :volume_id,             String
      magic     :resizable,             Whatever, :default => false  # FIXME: Boolean?
      magic     :snapshot_id,           String
      magic     :snapshot_name,         String
      magic     :tags,                  Hash,     :default => {}
    end
    class RaidGroup < Volume
      # volumes that comprise this raid group
      magic     :sub_volumes,           Array,    :default => []
      # RAID level (http://en.wikipedia.org/wiki/RAID#Standard_levels)
      magic     :level,                 String
      # Raid chunk size (https://raid.wiki.kernel.org/articles/r/a/i/RAID_setup_cbb2.html)
      magic     :chunk,                 String
      # read-ahead buffer
      magic     :read_ahead,            String

      # Overrides of Volume field defaults
      magic     :attachable,            Whatever, :default => false
      magic     :formattable,           Whatever, :default => true
      magic     :mount_options,         String,   :default => 'defaults,nobootwait,noatime,nouuid,comment=ironfan'
    end
  end
end
