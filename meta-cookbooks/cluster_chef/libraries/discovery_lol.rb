module ClusterChef
  ::ClusterChef::Discovery.class_eval do
    # --------------------------------------------------------------------------
    #
    # Alternate syntax
    #

    # alias for #discovers
    #
    # @example
    #   can_haz(:redis) # => {
    #     :in_yr       => 'uploader_queue',             # alias for realm
    #     :mah_bukkit  => '/var/log/uploader',          # alias for logs
    #     :mah_sunbeam => '/usr/local/share/uploader',  # home dir
    #     :ceiling_cat => 'http://10.80.222.69:2345/',  # dashboards
    #     :o_rly       => ['volumes'],        # concerns
    #     :zomg        => ['redis_server'],             # daemons
    #     :btw         => %Q{Queue to process uploads}  # description
    #   }
    #
    #
    def can_haz(name, options={})
      system = discover(name, options)
      MAH_ASPECTZ_THEYR.each do |lol, real|
        system[lol] = system.delete(real) if aspects.has_key?(real)
      end
      system
    end

    # alias for #announces. As with #announces, all params besides name are
    # optional -- follow the conventions whereever possible. MAH_ASPECTZ_THEYR
    # has the full list of alternate aspect names.
    #
    # @example
    #   # announce a redis; everything according to convention except for the
    #   # custom log directory.
    #   i_haz_a(:redis, :mah_bukkit => '/var/log/uploader' )
    #
    def i_haz_a(system, aspects)
      MAH_ASPECTZ_THEYR.each do |lol, real|
        aspects[real] = aspects.delete(lol) if aspects.has_key?(lol)
      end
      announces(system, aspects)
    end

    # Alternate names for machine aspects. Only available through #i_haz_a and
    # #can_haz.
    #
    MAH_ASPECTZ_THEYR = {
      :in_yr => :realm, :mah_bukkit => :logs, :mah_sunbeam => :home,
      :ceiling_cat => :dashboards, :o_rly => :concerns, :zomg => :daemons,
      :btw => :description,
    }
  end
end
