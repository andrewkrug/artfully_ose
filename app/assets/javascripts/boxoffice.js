//= require store/jquery.validate
//= require_self

$(function() {
  sliderOffset = $('.navbar').width()+100;
  $('#boxoffice').css({right:-sliderOffset});
  $('#doorlist').css({left:-sliderOffset});

  setPageHeight();

  // moving between door list and box office
  $('.page-nav li a').click(function() {
    switchBetweenBoxofficeAndDoorlist($(this).attr('href'));
    return false;
  });

  // focus on search bar for doorlist
  $('input#search').focus();

  // set doorlist progress bar
  updateProgressBar();

  // clicking + or - buttons for tickets
  $('a.add').click(function() {
    var field = $(this).prev();
    var currentVal = parseInt(field.val());
    if (isNaN(currentVal)) { currentVal = 0 };
    var newVal = currentVal + 1;
    var limit = parseInt(field.attr('data-remaining'));
    if (newVal <= limit) {
      $(this).siblings('.ticket-type').find('.remaining').text(limit-newVal);
      field.val(newVal).trigger('change');
    }
  });
  $('a.subtract').click(function() {
    var field = $(this).next();
    var currentVal = parseInt(field.val());
    if (isNaN(currentVal)) { currentVal = 1 };
    var newVal = currentVal - 1;
    var limit = parseInt(field.attr('data-remaining'));
    var remain = limit-newVal;
    if (newVal >= 0) {
      field.val(newVal).trigger('change');
      if (remain >=0) {
        $(this).siblings('.ticket-type').find('.remaining').text();
      }
    }
  });

  // typing in a ticket quantity
  $('.ticket-quantity').keyup(function() {
    var field = $(this);
    var val = parseInt(field.val());
    var limit = parseInt(field.attr('data-remaining'));
    if (isNaN(val) || val < 0) {
      field.val(0);
      $(this).select();
    } else {
      if (val > limit) { val = limit };
      field.val(val);
      $(this).siblings('.ticket-type').find('.remaining').text(limit-val);
    }
  });
  // highlight the whole input field
  $('.ticket-quantity').click(function () {
     $(this).select();
  });

  // discount codes are not case-sensitive
  $('#order-discount').keyup(function() {
    $('#order-discount').val($('#order-discount').val().toUpperCase());
  });

  UPDATING_TOTAL_REQUEST = null;
  $(".ticket :input, #order-discount, #order-donation").bind("keyup change", function(e) {
    var spinner = $('#order-total .loading');
    var total = $('#order-total .message');
    spinner.show();
    total.hide();

    // if a previous request is still being processed
    // abort and don't listen for response
    if(UPDATING_TOTAL_REQUEST) UPDATING_TOTAL_REQUEST.abort();

    // wait 1 second after change
    delay(function(){

      var params = $('.boxoffice-form').serialize();
      delete params['commit']; // dont actually purchase

      UPDATING_TOTAL_REQUEST = $.post( $('.boxoffice-form').attr('action'), params)
        .done(function(response) {
          updateTotal(response);
        })
        .fail(function(jqXHR, textStatus, errorThrown) {
          if(textStatus != 'abort') total.text('An error has occured. Please try again.');
        })
        .always(function(data, textStatus, errorThrown) {
          if(textStatus != 'abort') {
            total.show();
            spinner.hide();
            UPDATING_TOTAL_REQUEST = null;
          }
        });

    }, 1000 );
  });

  // select payment type
  $(".payment-select").on("click", "a.btn", function() {
    $('.payment-fields').hide();
    $('label span.required').hide();

    if($(this).hasClass('active')) {
      $('.payment-select a.btn').removeClass('active');
      $('#payment_method').val('');

    } else {
      $('.payment-select a.btn').removeClass('active');
      $(this).addClass('active');
      var payment = $(this).attr('data-payment-select');
      $('#payment_method').val(payment);

      if(payment == 'credit'){
        $('#credit-fields').show();
        $('#credit_card_number').focus();
        $('label span.email-required').show();
        $('label span.name-required').show();
        $('label span.contact-required').show();
      } else if(payment == 'comp') {
        $('label span.name-required').show();
      } else if(payment == 'check') {
        $('#check-fields').show();
      }
    }

    $('#payment_method').trigger('change') // trigger change so form validness can be checked
  });

  $('#doorlist.page').on('click', 'tr.buyer', function() {
    $('tr.buyer').removeClass('active');
    $(this).addClass('active');
    $('.buyer-details').hide();
    $('#buyer-details').html($(this).find('.buyer-details-hidden').html());
    // set height to height of page so it has it's own scroll
    offset = parseInt($('#buyer-details').css('top'), 10) + $('#buyer-details .content').position().top;
    $('#buyer-details .content').css({height: ($(window).height() - offset) });
    $('#buyer-details').fadeIn(100);
  });

  $('#doorlist.page').on('click', '.door-list-checkbox', function() {
    var checkbox = $(this);
    buyerId = checkbox.attr('data-buyer-id');
    ticketId = checkbox.attr('data-ticket-id');
    checked = checkbox.is(':checked');
    collection = checked ? 'validated' : 'unvalidated';

    // check the duplicated checkbox
    $("[data-ticket-id="+ticketId+"]").attr('checked', checked);

    // set the visual marker at the beginning of the row
    var icon = $("tr.buyer[data-buyer-id="+buyerId+"]").find('.remaining-ticket-indicator')
    available_tickets = $(":checkbox[data-buyer-id="+buyerId+"]:not(:checked)").length;
    unavailable_tickets = $(":checkbox[data-buyer-id="+buyerId+"]:checked").length;

    icon.removeClass(); // remove current icon
    icon.addClass('remaining-ticket-indicator');

    if(available_tickets == 0) {
      icon.addClass('fa fa-circle');
    } else if(unavailable_tickets == 0) {
      icon.addClass('fa fa-circle-o');
    } else {
      icon.addClass('fa fa-adjust');
    }

    updateProgressBar();

    $.ajax({
      type: "PUT",
      url: '/tickets/'+ticketId+'/'+collection+'.json'
    });
  });

  $('tr.buyer:first').click();

  // search doorlist
  $("#page-holder").on("keyup", "#live_search", function(){
    // Retrieve the input field text
    var filter = $(this).val();

    // Loop through the buyers list
    $("tr.buyer").each(function(){
      // If the list item does not contain the text phrase hide it
      if ($(this).attr('data-search-blob').search(new RegExp(filter, "i")) < 0) {
        $(this).hide();
      } else {
        $(this).show();
      }
    });

    // if only 1 buyer remains, activate it
    if ($("tr.buyer:visible").length === 1) {
      $("tr.buyer:visible").click();
      // dismiss ios keyboard
      // $('input:focus').blur();
    }
  });

  $("#user-info #person_first_name").autocomplete({
    minLength: 1,
    source: function(request, response) {
      $.getJSON("/people?utf8=%E2%9C%93&commit=Search", { search: request.term }, function(people) {
        $('#person_first_name').popover('destroy');
        var responsePeople = new Array();

        $.each(people, function (i, person) {
          person = cleanJsonPerson(person)
          responsePeople[i]  = "<li data-person-id='"+person.id+"' data-person-email='"+person.email+"'>";
          responsePeople[i] += "<h4><span class='first-name'>"+person.first_name+"</span> <span class='last-name'>"+person.last_name+"</span></h4>";
          if(person.company_name) { responsePeople[i] += "<span class='company-name'>"+person.company_name+"</span>" }
          responsePeople[i] += "</li>";
        });

        if(responsePeople.length) {
          $('#person_first_name').popover({
            content:  responsePeople,
            html:     true,
            title:    'Existing people',
            position: 'left',
            trigger:  'manual',
            container:'#existing-user-popover'
          });
          $('#person_first_name').popover('show');
        }

        response(null)
      });
    }
  });

  $('#existing-user-popover').on('click', 'li', function() {
    person = $(this);
    $('#person_first_name').val(person.find('.first-name').text());
    $('#person_last_name').val(person.find('.last-name').text());
    $('#person_email').val(person.attr('data-person-email'));
    $('#person_id').val(person.attr('data-person-id'));
    $('#person_first_name').popover('destroy');
    validateForm();
    return false;
  });

  // If they enter a custom email address (or change what was autocompleted, we have to clear the person id)
  $("#user-info input").change( function () {
    $("input#person_id").val("");
    $('#person_first_name').popover('destroy');
  })

  // handle swipe from a magtek card reader
  $('#credit_card_number').keyup(function() {
    var val = $(this).val();
    if (val.slice(0,2) === '%B') {
      length = 0;

      // there is a delay the data being entered in the field after a swipe
      // make sure we wait until it is all there
      do {
        val = $(this).val();
        setTimeout(length = val.length, 100);
      } while (length < val.length);

      // shamlessly lifted from
      // https://github.com/fracturedatlas/swiper/
      tracks = val.match(/^%(.*)\?;(.*)\?$/);
      if (tracks) {
        raw_track1    = tracks[1];
        track1_groups = raw_track1.match(/^(.)(\d*)\^([^\/]*)\/(.*)\^(..)(..)(.*)$/);
        $('#credit_card_number').val(track1_groups[2]);

        month = track1_groups[6];
        if (month[0] === '0') { month = month[1] }; // removing leading zero for select
        $('#credit_card_month').val(month);

        year = track1_groups[5];
        if (year.length === 2) { year = '20'+year }; // add '20' for select
        $('#credit_card_year').val(year);
      }
    }
  });

  // disable submit button until form is valid
  $('.boxoffice-form input').change(function() {
    validateForm();
  });

  $('.boxoffice-form').validate({
    submitHandler: function(form) {
      processForm(form);
    },
    highlight: function(element, errorClass) {
      $(element).closest('.control-group').addClass(errorClass);
    },
    unhighlight: function(element, errorClass) {
      $(element).closest('.control-group').removeClass(errorClass);
    },
    ignore: ".ignore-validation",
    messages: {
      total: null,
      payment_method: 'Please select a payment method.',
    },
    rules: {
      'total': {
        required: true
      },
      'payment_method': {
        required: function(element) {
          return (
                    parseFloat($('#total').val()) > 0.0
                 )
        }
      },
      'person[first_name]': {
        required: function(element) {
          return (
                    $('#payment_method').val() === 'credit' ||
                    $('#payment_method').val() === 'comp'
                 )
        }
      },
      'person[last_name]': {
        required: function(element) {
          return (
                    $('#payment_method').val() === 'credit' ||
                    $('#payment_method').val() === 'comp'
                 )
        }
      },
      'person[email]': {
        email: true,
        required: function(element) {
          return (
                    $('#payment_method').val() === 'credit' &&
                    !$.trim($('#person_phone').val()).length // empty?
                 )
        }
      },
      'person[phone]': {
        required: function(element) {
          return (
                    $('#payment_method').val() === 'credit' &&
                    !$.trim($('#person_email').val()).length // empty?
                 )
        }
      },
      'credit_card[number]': {
        creditcard: true,
        required: function(element) {
          return (
                    $('#payment_method').val() === 'credit'
                 )
        }
      },
    }
  });
});

// called after a successful purchase
function clearBoxOfficeForm() {
  $(":input:not([type=button],[type=submit],[type=checkbox],button,[name=authenticity_token])").val('');
  $('#auto_check_in[type=checkbox]').prop('checked', false);
  $('input.ticket-quantity').val('0');
  $('.payment-select a.btn').removeClass('active');
  $('#payment_method').val('');
  $('#order-total .message').text('$0.00 Total');
  $('.discount .message').hide();
  $('#person_first_name').popover('destroy');
  $('#checkout-now-button').attr('disabled','disabled');
};

// called after valid form is submitted
function processForm(form) {
  var f = $(form);
  var modalHeader = $('#submit-confirmation .modal-header h3');
  var modalBody = $('#submit-confirmation .modal-body .content');
  var spinner = $('#submit-confirmation .modal-body .loading');
  modalHeader.text('Processing...');
  modalBody.text('');
  spinner.show();
  $('.modal-close').hide();

  $('#submit-confirmation').modal({keyboard:false, backdrop:'static'});

  $.post( f.attr('action'), f.serialize())
    .done(function(response) {
      var message = '';
      if (response['message']) { message += response['message'] };
      if (response['error'])   { message += response['error'] };

      if(response['sale_made']) {
        modalHeader.text('Purchase Complete');
        clearBoxOfficeForm();
        updateRemainingTickets(response['ticket_types']);
        updateDoorlist(response['buyer']['id']);
      } else {
        modalHeader.text('Error');
      }
      modalBody.text(message);
    })
    .fail(function() {
      modalHeader.text('An error has occured.');
      modalBody.text('Please try your purchase again.');
    })
    .always(function() {
      spinner.hide();
      $('.modal-close').show();
    });
};

// called after valid form is submitted
function updateRemainingTickets(ticket_types) {
  $.each( ticket_types, function( key, ticket ) {
    var row = $('.ticket[data-ticket-id='+ticket.id+']');
    var input = row.find('input');

    $('.remaining[data-ticket-id='+ticket.id+']').text(ticket.available);
    row.attr('data-remaining', ticket.available);
    input.attr('data-remaining', ticket.available);

    if(ticket.available > 0) {
      input.removeAttr('disabled');
      row.removeClass('unavailable');
    } else {
      // TODO see if these are in your current cart before disabling
      // input.attr('disabled', 'disabled');
      // row.addClass('unavailable');
    }
  });
};

// utility
function cleanJsonPerson(jsonPerson) {
  jsonPerson.first_name = ( jsonPerson.first_name == null ? "" : jsonPerson.first_name );
  jsonPerson.last_name = ( jsonPerson.last_name == null ? "" : jsonPerson.last_name );
  jsonPerson.email = ( jsonPerson.email == null ? "" : jsonPerson.email );
  jsonPerson.company_name = ( jsonPerson.company_name == null ? "" : jsonPerson.company_name );
  return jsonPerson
};

function updateSelectedPerson(personId, personFirstName, personLastName, personEmail) {
  $("input#person_id").val(personId);
  $("input#person_first_name").val(personFirstName);
  $("input#person_last_name").val(personLastName);
  $("input#person_email").val(personEmail);
};


// when a ticket, donation, or discount code is changed
function updateTotal(response) {
  var total = $('#order-total .message');
  total.text(response['total']*0.01);
  total.formatCurrency({symbol:'$'});
  total.text(total.text() + ' Total');

  // invalidate form if no tickets and total 0
  if ((response['tickets'].length > 0) || (response['total'] > 0)) {
    $('input#total').val(response['total']);
  } else {
    $('input#total').val('');
  }
  // trigger change so form validness can be checked;
  $('input#total').trigger('change');

  // update "remaining tickets"
  updateRemainingTickets(response['ticket_types']);

  // handle discount
  handleDiscount(response)
};

function handleDiscount(response) {
  var discountMessage = $('.discount .message');
  discountMessage.show();
  if(response['discount_error']) {
    // something incorrect with discount code
    discountMessage.text(response['discount_error']);
  } else if(response['discount_amount'] > 0) {
    // success, discount greater than 0
    discountMessage.text(response['discount_amount']*-0.01);
    discountMessage.formatCurrency({symbol:'$'});
    discountMessage.text(discountMessage.text() + ' discount');
  } else if($.trim($('#order-discount').val()).length) {
    // success but discount < 0 and something in discount input
    discountMessage.text('No valid discount found.');
  } else {
    discountMessage.hide();
  }
}

// change doorlist progress bar
function updateProgressBar() {
  all_available_tickets = $("#door-list-table :checkbox:not(:checked)").length;
  all_unavailable_tickets = $("#door-list-table :checkbox:checked").length;
  total_tickets = all_available_tickets+all_unavailable_tickets;
  width = ((all_unavailable_tickets/total_tickets) * 100)+'%';
  $('.progress .bar').css({width:width});
  $('.progress .bar').text(all_unavailable_tickets+'/'+total_tickets+' checked in');
};

// animate transition
function switchBetweenBoxofficeAndDoorlist(selectedId) {
  $('.page-nav li').removeClass('active');
  $('[href='+selectedId+']').parent('li').addClass('active');

  if(selectedId=='#doorlist') {
    $('#boxoffice').animate({right:-sliderOffset}, 200)
    $('#doorlist').animate({left:0}, 200)
  } else {
    $('#doorlist').animate({left:-sliderOffset}, 200)
    $('#boxoffice').animate({right:0}, 200)
  }
}

function updateDoorlist(buyerId) {
  $('#doorlist.page').fadeOut();
  jQuery.get($('#doorlist.page').attr('data-partial-href'), function(data) {
    $('#doorlist.page').html(data);
    updateProgressBar();
    setPageHeight();
    $('#doorlist.page').fadeIn();
    $('tr.buyer[data-buyer-id='+buyerId+']').click();
  })
}

// height of the page has to be set manually
// because the boxoffice and doorlist pages are positioned absolute (so they can slide)
function setPageHeight() {
  $('#page-holder').css({
    height: Math.max($('#boxoffice').height(), $('#doorlist').height()) + 300
  });
}

function validateForm() {
  if($('.boxoffice-form').valid()) {
    $('#checkout-now-button').removeAttr('disabled');
    $('#checkout-now-button').addClass('btn-success');
  } else {
    $('#checkout-now-button').attr('disabled','disabled');
    $('#checkout-now-button').removeClass('btn-success');
  }
}

var delay = (function(){
  var timer = 0;
  return function(callback, ms){
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})();
