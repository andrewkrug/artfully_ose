var eventEnabled = true

$("document").ready(function(){

  $(".widget_type").change(function(){
    if($(this).attr('value') == 'event' || $(this).attr('value') == 'both') { 
      $('.events').removeClass('hidden');
			eventEnabled = true
    } else {
      $('.events').addClass('hidden');
			eventEnabled = false
    }   
  });

})

$("#widget-form").bind("ajax:beforeSend", function(evt, data, status, xhr){
	if (eventEnabled && $('#event_id').val() == "") {
		setErrorMessage("Please select an event")
		return false;
	} else {
		$('.flash').remove()
	}
});

$("#widget-form").bind("ajax:success", function(evt, data, status, xhr){
	$('.the-code').removeClass('hidden')
	$('#widget-code').html(data)
});