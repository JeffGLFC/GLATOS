class Deployment < ActiveRecord::Base
  require 'rgeo/geo_json'
  include PgSearch

  pg_search_scope :search_all,
                  :against => [:model],
                  :using => {
                    :tsearch => {:prefix => true},
                    :trigram => {}
                  },
                  :associated_against => {
                    :otn_array => [ :code,
                                    :description,
                                    :waterbody
                                  ]
                  }

  belongs_to :study
  belongs_to :otn_array
  has_one :retrieval, :dependent => :destroy

  set_rgeo_factory_for_column(:location, RGeo::Geographic.spherical_factory(:srid => 4326))

  def DT_RowId
    self.id
  end

  def station
    "%03d" % read_attribute(:station) rescue nil
  end

  def rcv_modem_address
    "%03d" % read_attribute(:rcv_modem_address) rescue nil
  end

  def code
    "#{otn_array.code}-#{station}"
  end

  def geo
    return RGeo::GeoJSON.encode(self.location)
  end

  def geojson
    removals = ["location","id","station","otn_array_id"]
    s = self.attributes.delete_if {|key, value| removals.include?(key) }
    s[:code] = code
    s[:recovered] = ending
    s[:otn_array] = {:code => otn_array.code, :description => otn_array.description, :waterbody => otn_array.waterbody, :region => otn_array.region}
    feat = RGeo::GeoJSON::Feature.new(self.location, self.id, s)
    RGeo::GeoJSON.encode(feat)
  end

  def latitude(round=3)
    location.latitude.round(round)
  end

  def longitude(round=3)
    location.longitude.round(round)
  end

  def ending
    unless proposed
      return retrieval.recovered rescue nil
    else
      return proposed_ending
    end
  end

end

#
# == Schema Information
#
# Table name: deployments
#
#  id                :integer         not null, primary key
#  start             :datetime
#  study_id          :integer
#  location          :spatial({:srid= indexed
#  otn_array_id      :integer
#  station           :integer
#  model             :string(255)
#  seasonal          :boolean
#  frequency         :integer
#  riser_length      :integer
#  bottom_depth      :integer
#  instrument_depth  :integer
#  instrument_serial :string(255)
#  rcv_modem_address :integer
#  deployed_by       :string(255)
#  vps               :boolean
#  consecutive       :integer
#

