module Ironfan
  class Dsl

    class Volume < Ironfan::Dsl
      field     :name,                  String

      magic     :attachable,            String,   :default => 'ebs'
      magic     :availability_zone,     String
      magic     :create_at_launch,      :boolean, :default => false
      magic     :device,                String
      magic     :formattable,           :boolean, :default => false
      magic     :fstype,                String,   :default => 'xfs'
      magic     :in_raid,               String
      magic     :keep,                  :boolean, :default => true
      magic     :mount_dump,            String
      magic     :mount_pass,            String
      magic     :mount_options,         String,   :default => 'defaults,nouuid,noatime'
      magic     :mount_point,           String
      magic     :mountable,             :boolean, :default => true
      magic     :size,                  String
      magic     :volume_id,             String
      magic     :resizable,             :boolean, :default => false
      magic     :snapshot_id,           String
      magic     :snapshot_name,         String
      magic     :tags,                  Hash,     :default => {}

      VOLUME_IDS ||= {}
      VOLUME_IDS.merge!({
                            :blank_xfs             => 'snap-d9c1edb1',
                            :blank_xfs_tokyo       => 'snap-049d1921',
                            :blank_xfs_california  => 'snap-514b5c5a', # us-west-1
                        })

      def snapshot_id(*)
        Ironfan.todo("CODE SMELL: EBS specific information in Dsl::Volume::VOLUME_IDS")
        super || VOLUME_IDS[snapshot_name]
      end
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
      magic     :attachable,            :boolean, :default => false
      magic     :formattable,           :boolean, :default => true
      magic     :mount_options,         String,   :default => 'defaults,nobootwait,noatime,nouuid,comment=ironfan'
    end

  end
end
