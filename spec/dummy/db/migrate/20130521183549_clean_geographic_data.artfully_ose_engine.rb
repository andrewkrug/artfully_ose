# This migration comes from artfully_ose_engine (originally 20130329201707)
class CleanGeographicData < ActiveRecord::Migration
  def up
    Address.all.each do |address|
      case address.country
      when /\d{5}/
        address.zip = address.country
        address.country = "United States"
      when /United States|^US$|^USA$|U\.S\./
        address.country = "United States"
      when /United Kingdom|^UK$|U\.K\./
        address.country = "United Kingdom"
      when /Canada|^CAN$/
        address.country = "Canada"
      when /Switzerland|^SWI$/
        address.country = "Switzerland"
      when /Israel|^ISR$/
        address.country = "Israel"
      when /Sweden/i
        address.country = "Sweden"
      when /Argentina/i
        address.country = "Argentina"
      when /Brazil/i
        address.country = "Brazil"
      when /Russia/i
        address.country = "Russia"
      when /Philippines/i
        address.country = "Philippines"
      end

      case address.state
      when /Alabama|^AL$/i
        address.state = "Alabama"
        address.country = "United States"
      when /Alaska|^AK$/i
        address.state = "Alaska"
        address.country = "United States"
      when /Arizona|^AZ$/i
        address.state = "Arizona"
        address.country = "United States"
      when /Arkansas|^AR$/i
        address.state = "Arkansas"
        address.country = "United States"
      when /California|^CA$|Los Angeles/i
        address.state = "California"
        address.country = "United States"
      when /Colorado|^CO$/i
        address.state = "Colorado"
        address.country = "United States"
      when /Connecticut|^CT$/i
        address.state = "Connecticut"
        address.country = "United States"
      when /Delaware|^DE$/i
        address.state = "Delaware"
        address.country = "United States"
      when /Florida|^FL$/i
        address.state = "Florida"
        address.country = "United States"
      when /Georgia|^GA$/i
        address.state = "Georgia"
        address.country = "United States"
      when /Hawaii|^HI$/i
        address.state = "Hawaii"
        address.country = "United States"
      when /Idaho|^ID$/i
        address.state = "Idaho"
        address.country = "United States"
      when /Illinois|^IL$/i
        address.state = "Illinois"
        address.country = "United States"
      when /Indiana|^IN$/i
        address.state = "Indiana"
        address.country = "United States"
      when /Iowa|^IA$/i
        address.state = "Iowa"
        address.country = "United States"
      when /Kansas|^KS$/i
        address.state = "Kansas"
        address.country = "United States"
      when /Kentucky|^KY$/i
        address.state = "Kentucky"
        address.country = "United States"
      when /Louisiana|^LA$/i
        address.state = "Louisiana"
        address.country = "United States"
      when /Maine|^ME$/i
        address.state = "Maine"
        address.country = "United States"
      when /Maryland|^MD$|MD - Maryland/i
        address.state = "Maryland"
        address.country = "United States"
      when /Massachusetts|^MA$/i
        address.state = "Massachusetts"
        address.country = "United States"
      when /Michigan|^MI$/i
        address.state = "Michigan"
        address.country = "United States"
      when /Minnesota|^MN$/i
        address.state = "Minnesota"
        address.country = "United States"
      when /Mississippi|^MS$/i
        address.state = "Mississippi"
        address.country = "United States"
      when /Missouri|^MO$/i
        address.state = "Missouri"
        address.country = "United States"
      when /Montana|^MT$/i
        address.state = "Montana"
        address.country = "United States"
      when /Nebraska|^NE$/i
        address.state = "Nebraska"
        address.country = "United States"
      when /Nevada|^NV$/i
        address.state = "Nevada"
        address.country = "United States"
      when /New Hampshire|^NH$/i
        address.state = "New Hampshire"
        address.country = "United States"
      when /New Jersey|^NJ$/i
        address.state = "New Jersey"
        address.country = "United States"
      when /New Mexico|^NM$/i
        address.state = "New Mexico"
        address.country = "United States"
      when /New York|^NY$/i
        address.state = "New York"
        address.country = "United States"
      when /North Carolina|^NC$|NC\: North Carolina/i
        address.state = "North Carolina"
        address.country = "United States"
      when /North Dakota|^ND$/i
        address.state = "North Dakota"
        address.country = "United States"
      when /^Ohio|^OH$/i
        address.state = "Ohio"
        address.country = "United States"
      when /Oklahoma|^OK$/i
        address.state = "Oklahoma"
        address.country = "United States"
      when /Oregon|^OR$/i
        address.state = "Oregon"
        address.country = "United States"
      when /Pennsylvania|^PA$/i
        address.state = "Pennsylvania"
        address.country = "United States"
      when /Rhode Island|^RI$/i
        address.state = "Rhode Island"
        address.country = "United States"
      when /South Carolina|^SC$/i
        address.state = "South Carolina"
        address.country = "United States"
      when /South Dakota|^SD$/i
        address.state = "South Dakota"
        address.country = "United States"
      when /Tennessee|^TN$/i
        address.state = "Tennessee"
        address.country = "United States"
      when /Texas|^TX$/i
        address.state = "Texas"
        address.country = "United States"
      when /Utah|^UT$/i
        address.state = "Utah"
        address.country = "United States"
      when /Vermont|^VT$/i
        address.state = "Vermont"
        address.country = "United States"
      when /^Virginia|^VA$/i
        address.state = "Virginia"
        address.country = "United States"
      when /Washington|^WA$/i
        address.state = "Washington"
        address.country = "United States"
      when /West Virginia|^WV$/i
        address.state = "West Virginia"
        address.country = "United States"
      when /Wisconsin|^WI$/i
        address.state = "Wisconsin"
        address.country = "United States"
      when /Wyoming|^WY$/i
        address.state = "Wyoming"
        address.country = "United States"
      when /American Samoa|^AS$/i
        address.state = "American Samoa"
        address.country = "United States"
      when /District of Columbia|^DC$/i
        address.state = "District of Columbia"
        address.country = "United States"
      when /Federated States of Micronesia|^FM$/i
        address.state = "Federated States of Micronesia"
        address.country = "United States"
      when /Guam|^GU$/i
        address.state = "Guam"
        address.country = "United States"
      when /Marshall Islands|^MH$/i
        address.state = "Marshall Islands"
        address.country = "United States"
      when /Northern Mariana Islands|^MP$/i
        address.state = "Northern Mariana Islands"
        address.country = "United States"
      when /Palau|^PW$/i
        address.state = "Palau"
        address.country = "United States"
      when /Puerto Rico|^PR$/i
        address.state = "Puerto Rico"
        address.country = "United States"
      when /Virgin Islands|^VI$/i
        address.state = "Virgin Islands"
        address.country = "United States"
      when /Armed Forces Africa/i
        address.country = "United States"
      when /Armed Forces Americas/i
        address.country = "United States"
      when /Armed Forces Canada/i
        address.country = "United States"
      when /Armed Forces Europe/i
        address.country = "United States"
      when /Armed Forces Middle East/i
        address.country = "United States"
      when /Armed Forces Pacific|^AP$/i
        address.state = "Armed Forces Pacific"
        address.country = "United States"
      end

      address.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
