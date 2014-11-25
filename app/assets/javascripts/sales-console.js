//= require store/jquery.validate
//= require_self

$("document").ready(function() {
  
  $('#event_selector').change(function () {
    event_id = $('#event_selector').val()
    person_id = $('#event_selector').attr('data-person-id')

    person_query_string = ""
    if (person_id != undefined) {
      person_query_string = "?person_id=" + person_id
    }

    if( event_id ) {
      $('#show-select-container').show()
      $('#show-select-controls').addClass("loading")
      $('#show_selector').prop("disabled", true)
      $('#ticket-list').html("&nbsp;");

      jQuery.getJSON("/console_sales/events/" + event_id + person_query_string, function(data){
      })
      .done(function(data) {
        $('#show_selector')
          .find('option')
          .remove()

        $('#show-select-controls').removeClass("loading")
        $('#show-select-container').show()

        $('#show_selector').append($("<option></option>"))

        $.each(data, function(index, el) {
          $('#show_selector')
            .append($("<option></option>")
            .attr("value",el.id)
            .text(el.show_time));
        })

        $('#show_selector').prop("disabled", false)
      })
      .fail(function() {
        //TODO
      })
    } else {
      $('#show-select-container').hide()
    }
  })

  $('#show-select-container').change(function () {
    show_id = $('#show_selector').val()    
    person_id = $('#show_selector').attr('data-person-id')

    person_query_string = ""
    if (person_id != undefined) {
      person_query_string = "?person_id=" + person_id
    }

    $.ajax({
      url: "/console_sales/shows/" + show_id + person_query_string,
      beforeSend: function ( xhr ) {
        $('#ticket-list').html("&nbsp;");
        $('#ticket-list').addClass("loading")
      }
    }).done(function ( data ) {
      $('#ticket-list').removeClass("loading")
      $('#ticket-list').html(data);
    }).fail(function ( data ) {
      $('#ticket-list').removeClass("loading")
    });
  })

  $("body").on("click", "a.btn", function() {
    $('label span.required').hide();
    $('.payment-fields').hide();
    $('a.btn').removeClass('active');

    $(this).addClass('active');
    var payment = $(this).attr('data-payment-select');
    $('#payment_method').val(payment).trigger('change'); // trigger change so form validness can be checked

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
  });

  $('#sales-console-payment-form').validate({
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
        required: true
      },
      'customer[first_name]': {
        required: function(element) {
          return (
                    $('#payment_method').val() === 'credit' ||
                    $('#payment_method').val() === 'comp'
                 )
        }
      },
      'customer[last_name]': {
        required: function(element) {
          return (
                    $('#payment_method').val() === 'credit' ||
                    $('#payment_method').val() === 'comp'
                 )
        }
      },
      'customer[email]': {
        email: true,
        required: function(element) {
          return (
                    $('#payment_method').val() === 'credit' &&
                    !$.trim($('#person_phone').val()).length // empty?
                 )
        }
      },
      'customer[phones_attributes][][number]': {
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

})