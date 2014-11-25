function hookupDoorListcheckboxes() {
  $('.door-list-checkbox').click( function () { 
    ticketId = $(this).attr('data-ticket-id')
    collection = $(this).is(':checked') ? 'validated' : 'unvalidated'
    $.ajax({
      type: "PUT",
      url: '/tickets/'+ticketId+'/'+collection+'.json'
    });
  });
}

$(document).ready(function () {
  hookupDoorListcheckboxes()
});