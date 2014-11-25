Geocoder.configure(:lookup => :test)

class Geocoder::Lookup::Test
  def self.read_stub(query_text)
    [
      {
        'latitude'     => 40.7144,
        'longitude'    => -74.006,
        'address'      => 'New York, NY, USA',
        'state'        => 'New York',
        'state_code'   => 'NY',
        'country'      => 'United States',
        'country_code' => 'US'
      }
    ]
  end
end
