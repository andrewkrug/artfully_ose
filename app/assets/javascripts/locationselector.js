/*
* LocationSelector v0.1
*/
(function($) {
  $.fn.locationSelector = function(options) {
    
    var settings = $.extend({
      'countryField'   : '#country',
      'countryDefault' : 'United States',
      'countryEmpty'   : true,
      'regionField'    : '#region',
      'regionEmpty'    : true,
      'regionClass'    : ''
    }, options);
  
    var countryField    = $(settings.countryField);
    var regionField     = $(settings.regionField);
    var regionFieldName = regionField.attr("name");
  
    var countryOptions = new Array(
      'Afghanistan','Albania','Algeria','American Samoa','Andorra','Angola','Anguilla','Antigua and Barbuda','Argentina','Armenia','Aruba','Australia',
      'Austria','Azerbaijan Republic','Bahamas','Bahrain','Bangladesh','Barbados','Belarus','Belgium','Belize','Benin','Bermuda','Bhutan','Bolivia',
      'Bosnia and Herzegovina','Botswana','Brazil','British Virgin Islands','Brunei Darussalam','Bulgaria','Burkina Faso','Burma','Burundi','Cambodia',
      'Cameroon','Canada','Cape Verde Islands','Cayman Islands','Central African Republic','Chad','Chile','China','Colombia','Comoros',
      'Congo, Democratic Republic of the','Congo, Republic of the','Cook Islands','Costa Rica','Cote d Ivoire (Ivory Coast)','Croatia, Republic of',
      'Cyprus','Czech Republic','Denmark','Djibouti','Dominica','Dominican Republic','Ecuador','Egypt','El Salvador','Equatorial Guinea','Eritrea',
      'Estonia','Ethiopia','Falkland Islands (Islas Malvinas)','Fiji','Finland','France','French Guiana','French Polynesia','Gabon Republic','Gambia',
      'Georgia','Germany','Ghana','Gibraltar','Greece','Greenland','Grenada','Guadeloupe','Guam','Guatemala','Guernsey','Guinea','Guinea-Bissau','Guyana',
      'Haiti','Honduras','Hong Kong','Hungary','Iceland','India','Indonesia','Ireland','Israel','Italy','Jamaica','Jan Mayen','Japan','Jersey','Jordan',
      'Kazakhstan','Kenya','Kiribati','Korea, South','Kuwait','Kyrgyzstan','Laos','Latvia','Lebanon','Liechtenstein','Lithuania','Luxembourg','Macau',
      'Macedonia','Madagascar','Malawi','Malaysia','Maldives','Mali','Malta','Marshall Islands','Martinique','Mauritania','Mauritius','Mayotte','Mexico',
      'Micronesia','Moldova','Monaco','Mongolia','Montserrat','Morocco','Mozambique','Namibia','Nauru','Nepal','Netherlands','Netherlands Antilles','New Caledonia',
      'New Zealand','Nicaragua','Niger','Nigeria','Niue','Norway','Oman','Pakistan','Palau','Panama','Papua New Guinea','Paraguay','Peru','Philippines',
      'Poland','Portugal','Puerto Rico','Qatar','Romania','Russian Federation','Rwanda','Saint Helena','Saint Kitts-Nevis','Saint Lucia','Saint Pierre and Miquelon',
      'Saint Vincent and the Grenadines','San Marino','Saudi Arabia','Senegal','Seychelles','Sierra Leone','Singapore','Slovakia','Slovenia','Solomon Islands',
      'Somalia','South Africa','Spain','Sri Lanka','Suriname','Svalbard','Swaziland','Sweden','Switzerland','Syria','Tahiti','Taiwan','Tajikistan','Tanzania',
      'Thailand','Togo','Tonga','Trinidad and Tobago','Tunisia','Turkey','Turkmenistan','Turks and Caicos Islands','Tuvalu','Uganda','Ukraine','United Arab Emirates',
      'United Kingdom','United States','Uruguay','Uzbekistan','Vanuatu','Vatican City State','Venezuela','Vietnam','Wallis and Futuna','Western Sahara',
      'Western Samoa','Yemen','Yugoslavia','Zambia','Zimbabwe');

    var regionOptions = {
      "Australia": new Array("Australian Capital Territory","New South Wales","Northern Territory","Queensland","South Australia","Tasmania","Victoria","Western Australia"),
      "Canada": new Array('Alberta','British Columbia','Manitoba','New Brunswick','Newfoundland and Labrador','Northwest Territories','Nova Scotia','Nunavut','Ontario','Prince Edward Island','Quebec','Saskatchewan','Yukon'),
      "France": new Array('Alsace','Aquitaine','Auvergne','Basse-Normandie','Bourgogne','Bretagne','Centre','Champagne-Ardenne','Corse','Franche-ComtÃ©','Guadeloupe','Guyanne','Haute-Normandie','ÃŽle-de-France','Languedoc-Rousillon','Limousin','Lorraine','Martinique','Midi-PyrÃ©nÃ©es','Nord-Pas-de-Calais','Pays de la Loire','Picardie','Poitou-Charentes','Provence-Alpes-CÃ´te d\'Azur','RÃ©union','RhÃ´ne-Alpes'),
      "United Kingdom": new Array('Aberdeen City','Aberdeenshire','Angus','Antrim','Argyll and Bute','Armagh','Avon','Bedfordshire','Berkshire','Blaenau Gwent','Borders','Bridgend','Bristol','Buckinghamshire','Caerphilly','Cambridgeshire','Cardiff','Carmarthenshire','Ceredigion','Channel Islands','Cheshire','Clackmannan','Cleveland','Conwy','Cornwall','Cumbria','Denbighshire','Derbyshire','Devon','Dorset','Down','Dumfries and Galloway','Dundee (City of)','Durham','East Ayrshire','East Dunbartonshire','East Lothian','East Renfrewshire','East Riding of Yorkshire','East Sussex','Edinburgh (City of)','Essex','Falkirk','Fermanagh','Fife Glasgow (City of)','Flintshire','Gloucestershire','Greater Manchester','Gwynedd','Hampshire','Herefordshire','Hertfordshire','Highland','Humberside','Humberside','Inverclyde','Isle of Anglesey','Isle of Man','Isle of Wight','Isles of Scilly','Kent','Lancashire','Leicestershire','Lincolnshire','London','Londonderry','Merseyside','Merthyr Tydfil','Middlesex','Midlothian','Monmouthshire','Moray','Neath Port Talbot','Newport','Norfolk','North Ayrshire','North Lanarkshire','North Yorkshire','Northamptonshire','Northumberland','Nottinghamshire','Orkney','Oxfordshire','Pembrokeshire','Perthshire and Kinross','Powys','Renfrewshire','Rhondda Cynon Taff','Rutland','Shetland','Shropshire','Somerset','South Ayrshire','South Lanarkshire','South Yorkshire','Staffordshire','Stirling','Suffolk','Surrey','Swansea','The Vale of Glamorgan','Torfaen','Tyne and Wear','Tyrone','Warwickshire','West Dunbartonshire','West Lothian','West Midlands','West Sussex','West Yorkshire','Western Isles','Wiltshire','Worcestershire','Wrexham'),
      "United States": new Array('Alaska','Alabama','American Samoa','Arkansas','Armed Forces Africa','Armed Forces Europe','Armed Forces Pacific','Arizona','California','Colorado','Connecticut','District of Columbia','Delaware','Federated States of Micronesia','Florida','Georgia','Guam','Hawaii','Iowa','Idaho','Illinois','Indiana','Kansas','Kentucky','Louisiana','Massachusetts','Northern Mariana Islands','Marshall Islands','Maryland','Maine','Michigan','Minnesota','Missouri','Mississippi','Montana','North Carolina','North Dakota','Nebraska','New Hampshire','New Jersey','New Mexico','Nevada','New York','Ohio','Oklahoma','Oregon','Pennsylvania','Palau','Puerto Rico','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Virginia','Virgin Islands','Vermont','Washington','Wisconsin','West Virginia','Wyoming')
    }
  
    return this.each(function() {
      var oldCountry = countryField.val() || settings.countryDefault;
    
      if(settings.countryEmpty) {
        countryField.append(
          $('<option></option>')
        );
      }
        
      for(i=0; i<=countryOptions.length; i++) {
        if(countryOptions[i]) {            
          countryField.append(
            $('<option value="'+countryOptions[i]+'">'+countryOptions[i]+'</option>')
          );
        }
      }

      countryField.val(oldCountry);
    
      function updateRegion() {
        var selectedCountry = countryField.val();
        var oldRegion       = regionField.val();

        if(typeof regionOptions[selectedCountry] != 'undefined') {
          var regions     = regionOptions[selectedCountry];
          var newSelect   = $('<select name="'+regionField.prop("name")+'" id="'+regionField.prop("id")+'" class="' + settings.regionClass + '"></select>');
          if(regionField.prop("placeholder")) {
              newSelect.prop("placeholder", regionField.prop("placeholder"));
          }
          
          regionField.replaceWith(newSelect);
          regionField = newSelect;

          if(settings.regionEmpty) {
            regionField.append(
              $('<option></option>')
            );
          }
          
          for(i=0; i<=regions.length; i++) {
            if(regions[i]) {
              var option = $('<option value="'+regions[i]+'">'+regions[i]+'</option>');
              regionField.append(option);            
            }
          }   
          regionField.val(oldRegion);

        } else {
          var newText = $('<input type="text" name="'+regionField.prop("name")+'" id="'+regionField.prop("id")+'" value="'+oldRegion+'" placeholder="'+regionField.prop("placeholder")+'">');
          regionField.replaceWith(newText);
          regionField = newText;
        }            
      }
      
      countryField.change(updateRegion);  
      updateRegion();
    }            
  )};
})(jQuery);