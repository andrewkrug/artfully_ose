function endsWith(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

$(document).ready(function(){

  hookupToggle()
  //$('#edit-address-modal').modal({show: false});

  $(document).locationSelector({
    'countryField' : '#payment_customer_address_country', 
    'regionField'  : '#payment_customer_address_state'
  });

  $(document).locationSelector({
    'countryField' : '#individual_address_attributes_country', 
    'regionField'  : '#individual_address_attributes_state'
  });

  // toggle a showing's sections
  $('#multi-show-container .title').click(function() {
    $(this).siblings('.sections').slideToggle();
    $(this).toggleClass('active');
  });

  // display the first showing's sections
  $('#multi-show-container .title').first().siblings('.sections').slideToggle();
  $('#multi-show-container .title').first().addClass('active');

  // when calendar is clicked
  $('td.has_show').click(function() {
    var loadingMessage = $('#loading-container #loading')
    var errorMessage = $('#loading-container #error')
    var date = $(this).attr('data-date');
    var targetLi = $("ul#shows li[data-date='" + date + "']");

    targetLi.hide();

    $.each(targetLi, function (index, targetLiEl) {
      targetLiEl = $(targetLiEl)
      var showUuid = targetLiEl.attr('data-show-uuid');

      $.ajax({
        url: "/store/shows/" + showUuid,
        beforeSend: function ( xhr ) {
          //can't use show() because it starts out hidden and show() won't work with that
          errorMessage.css('display', 'none')
          loadingMessage.css('visibility', 'visible')
          
          $("ul#shows li").parent().attr('style','opacity:.4')
        }
      }).done(function ( data ) {
        loadingMessage.css('visibility', 'hidden')
        $("ul#shows li").parent().attr('style','opacity:1')
        $("ul#shows li").hide();  
        targetLiEl.html(data);  
        targetLi.fadeIn('slow');
        hookupToggle() 
      }).error(function ( data ) {
        loadingMessage.css('visibility', 'hidden')
        errorMessage.css('display', 'block')
        errorMessage.css('visibility', 'visible')
      });
    });
  });

  $('#discount-link a').click(function(e) {
    e.preventDefault();
    $('tr#discount-link').hide();
    $('tr#discount-display').hide();
    $('tr#discount-input').show();
  });

  $('#pass-code-link a').click(function(e) {
    e.preventDefault();
    $('tr#pass-code-link').hide();
    $('tr#pass-code-display').hide();
    $('tr#pass-code-input').show();
  });

  // add * to required field labels
  $('label.required').append('&nbsp;<strong>*</strong>&nbsp;');

  $('.required').change(function(e) {
    validateElement($(this))
  });

  $('#shopping-cart-form').submit(function(e) {
    valid = validateForm();
    if (!valid) {
      e.preventDefault();
    } else {
      $('#complete-purchase').attr('disabled', 'true')
    }
  });
});

function updateRequiredFields() {
  var total = getTotal();
  $('input.nonzero-total').each(function() {
    if(cartTotal > 0) {
      $(this).addClass('required');
      $(this).removeAttr("disabled");
    } else {
      $(this).removeClass('required');
      $(this).attr("disabled", "disabled");
    }
  });
}

function validateElement(el) {
  return $('#shopping-cart-form').validate({
        errorElement: "span",
        errorClass:'help-inline',
        highlight: function(element, errorClass) {
          $(element).parents('.control-group').addClass('error');
        },
        unhighlight: function(element, errorClass) {
          $(element).parents('.control-group').removeClass('error');
        }
      }).element(el);
}

function validateForm() {
  var everythingValid = true;
  $('input.required').each(function() {
    v = validateElement("#" + $(this).attr('id'));
    if (!(v)) {everythingValid = false;}
  });


  $('.required-checkbox').each(function() {
    if ($(this).prop('checked') == false) {
      $(this).parent().addClass('error')
      everythingValid = false
    } else {
      $(this).parent().removeClass('error')
    }
  });

  if(!everythingValid) {
    $('.cart-error-message').show()
  } else {
    $('.cart-error-message').hide()
  }

  return everythingValid;
}

// show/hide extended event descriptions
function hookupToggle() {
  $('.truncated a.toggle, .not-truncated a.toggle').unbind('click')
  $('.truncated a.toggle, .not-truncated a.toggle').click(function(e) {
    e.preventDefault();
    $(this).parents('.toggle-truncated').find('.truncated, .not-truncated').toggle();
  });
}

$('.preset_radio').click(function() {
  $('#donation_amount_fixed').val($(this).val());
  $('#donation_amount').val(null);
});

$('#donation_amount').focus(function() {
  if($('#suggested_gift_42')) {
    $( '#suggested_gift_42' ).prop( "checked", true );
  }
});
