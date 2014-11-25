//= require jquery
//= require jquery_ujs
//= require jquery-lib
//= require jquery-migrate-1.2.1
//= require angular
//= require angular-resource
//= require locationselector
//= require_directory ./custom
//= require bootstrap
//= require wysihtml5-0.3.0.min.js
//= require bootstrap-wysihtml5.js
//= require_self
//= require change-membership

var artfully = angular.module("artfully", ['ngResource']);

function NewPersonCtrl($scope) {
  $scope.data = {
    type: "Individual",
    subtype: "Other"
  };

  $scope.final_subtype = function() {
    if ($scope.data.type == "Individual") {
      return "Individual";
    }
    return $scope.data.subtype;
  }
}

function NewHouseholdCtrl($scope) {
}

function EditHouseholdCtrl($scope) {
}

function EditPersonCtrl($scope) {
}

var CollectInfoCtrl = function($scope, $http) {
  $scope.data = {organization: {valid_name: true}};

  $scope.$watch("data.organization.name", function(oldValue, newValue) {
    //$http.post('/organizations/check_name.json', {name:$scope.data.organization.name, zip:$scope.data.organization.zip}).then(function(result){$scope.data.organization.valid_name = result.data.valid;});
  });

  $scope.$watch("data.organization.zip", function(oldValue, newValue) {
    //$http.post('/organizations/check_name.json', {name:$scope.data.organization.name, zip:$scope.data.organization.zip}).then(function(result){$scope.data.organization.valid_name = result.data.valid;});
  });
};

var EditOrganizationCtrl = function($scope, $http) {
  $scope.data = {organization: {valid_name: true}};

  $scope.$watch("data.organization.name", function(oldValue, newValue) {
    //$http.post('/organizations/check_name.json', {name:$scope.data.organization.name, zip:$scope.data.organization.zip}).then(function(result){$scope.data.organization.valid_name = result.data.valid;});
  });

  $scope.$watch("data.organization.zip", function(oldValue, newValue) {
    //$http.post('/organizations/check_name.json', {name:$scope.data.organization.name, zip:$scope.data.organization.zip}).then(function(result){$scope.data.organization.valid_name = result.data.valid;});
  });
};

artfully.factory("Organization", function($resource) {
  $resource('/organizations/:id', {id:'@id'}, {
    update: {method:"PUT"}
  });
});

zebra = function(table) {
    $("tr", table).removeClass("odd");
    $("tr", table).removeClass("even");
    $("tr:even", table).addClass("even");
    $("tr:odd", table).addClass("odd");
};

bindControlsToListElements = function () {
  $(".detailed-list li").hover(
    function(){
      $(this).find(".controls").stop(false,true).fadeIn('fast');},
    function(){
      $(this).find(".controls").stop(false,true).fadeOut('fast');});
};

function createErrorFlashMessage(msg) {
	$('#heading').after($(document.createElement('div'))
							.addClass('flash')
							.addClass('error')
							.addClass('alert')
							.addClass('alert-error')
							.html('<span>'+msg+'</span>'));

	$(".close").click(function(){
		$(this).closest('.flash').remove();
	});
}

function setErrorMessage(msg) {
	if($('.flash').length > 0) {
		$('.flash').fadeOut(400, function() {
			$(this).remove();
			createErrorFlashMessage(msg);
		});
	} else {
		createErrorFlashMessage(msg);
	}
}

function createFlashMessage(msg) {
	$('#heading').after($(document.createElement('div'))
							.addClass('flash')
							.addClass('success')
							.addClass('alert')
							.addClass('alert-info')
							.html('<span>'+msg+'</span>'));

	$(".close").click(function(){
		$(this).closest('.flash').remove();
	});
}

function setFlashMessage(msg) {
	if($('.flash').length > 0) {
		$('.flash').fadeOut(400, function() {
			$(this).remove();
			createFlashMessage(msg);
		});
	} else {
		createFlashMessage(msg);
	}
}

function bindEditOrderLink() {
  $("#edit-order-link, .edit-order-link").bind("ajax:complete", function(et, e){
    $("#edit-order-popup").html(e.responseText);
    $("#edit-order-popup").modal( "show" );
    activateControls();
    touchCurrency();
    return false;
  });
}

function singleShot() {
  $(".single-shot").parents("form").submit(function(){
    $(this).find(".single-shot").attr('disabled','disabled');
  });
}

function returnFalse() {
  return false;
}

var checkForFA = function() {
  if($('.no-fa').val().indexOf("Fractured Atlas") > -1) {
    $('.disablable').attr('disabled', 'disabled')
    $('.no-fa').popover( "show" )
  }
}

var clearFA = function() {
  if($('.no-fa').val().indexOf("Fractured Atlas") > -1) {
    $('.disablable').attr('disabled', 'disabled')
    $('.no-fa').popover( "show" )
  } else {
    $('.no-fa').popover( "hide" )
    $('.disablable').removeAttr("disabled");
  }
}

function bindLimitPopover() {
  $('#ticket_type_limit').popover({title: "Heads Up!", content: "Setting this to zero means that this ticket type will appear as SOLD OUT to patrons.", placement: "right", trigger: "manual"});

  $('#ticket_type_limit').keyup(function () {
    if (parseInt($('#ticket_type_limit').val()) == 0) {
      $('#ticket_type_limit').popover('show')
    } else {
      $('#ticket_type_limit').popover('hide')
    }
  })
}

function bindMemberTickets() {
  $('.member-ticket-yes').on('click', function(e) { $('.membership-fields', $(this).parent().parent().parent().parent()).show() })
  $('.member-ticket-no').on('click', function(e) { $('.membership-fields', $(this).parent().parent().parent().parent()).hide() })  

  jQuery.each($('.member-ticket-yes'), function() {
    if ($(this).prop("checked")) {
      $('.membership-fields', $(this).parent().parent().parent().parent()).show()
    } else {
      $('.membership-fields', $(this).parent().parent().parent().parent()).hide()
    }
  })
}

$(document).ready(function() {

	/*********** NEW BOOTSTRAP JS ***********/
	$(".alert").alert();

  $('.email-popup').popover({trigger:'focus'});

  if($.browser.mozilla) {
    $('.section-price-disabled *').css("pointer-events", "none");
  }

	$('.help').popover({ html : true });
	$('.edit-message, .delete-message').popover({title: "Editing / Deleting", content: "We can only edit or delete manually entered donations.", placement: "right"});
	
	$('.dropdown-toggle').dropdown();
	
	$('#nag').modal('show');

  $('.dropdown .dropdown-menu .disabled').on('click', function(e) {
    e.preventDefault();
  });

  $('.wysihtml5').wysihtml5()
	
	/*********** NEW ARTFULLY JS ************/

  $('.artfully-tooltip').tooltip();
  $('.no-fa').popover({trigger:'manual', title: "That's us not you!", content: "You cannot name your organization \"Fractured Atlas\". Use the name of your company, group, or business here. Fiscally sponsored projects of Fractured Atlas should use their project name here."})
  $('.no-fa').on('keyup', checkForFA);
  $('.no-fa').on('change', clearFA);

  $('#membership_type_offer_renewal').click(function () {
    $("#renewal-price-group").toggle();
  });

  if($("#membership_type_offer_renewal").is(':checked')) {
    $("#renewal-price-group").show();
  } else {
    $("#renewal-price-group").hide();
  }

  bindMemberTickets()
  bindLimitPopover()

	/*********** EXISTING ARTFUL.LY JS ******/

  singleShot();

  $(document).locationSelector({
    'countryField' : '#person_address_attributes_country',
    'regionField'  : '#person_address_attributes_state'
  });

  $(document).locationSelector({
    'countryField' : '#company_address_attributes_country',
    'regionField'  : '#company_address_attributes_state'
  });

  $(document).locationSelector({
    'countryField' : '#individual_address_attributes_country',
    'regionField'  : '#individual_address_attributes_state'
  });

  $(document).locationSelector({
    'countryField' : '#user_organization_country',
    'regionField'  : '#user_organization_state'
  });

  $(document).locationSelector({
    'countryField' : '#organization_country',
    'regionField'  : '#organization_state'
  });

  $(document).locationSelector({
    'countryField' : '#household_address_attributes_country',
    'regionField'  : '#household_address_attributes_state'
  });

  $(document).locationSelector({
    'countryField' : '#customer_address_country',
    'regionField'  : '#customer_address_state'
  });


  $("form .description").siblings("input").focusin(function(){
    $("form .description").addClass("active");
  }).focusout(function(){
    $("form .description").removeClass("active");
  });

  $(".zebra tbody").each(function(){
    zebra($(this));
  });

  $(".close").click(function(){
    $(this).closest('.flash').remove();
  });

  $(".new-window").parents("form").attr("target", "_blank");

  $("#main-menu").hover(
    function(){$("#main-menu li ul").stop().animate({height: '160px'}, 'fast');},
    function(){$("#main-menu li ul").stop().animate({height: '0px'}, 'fast');}
  );

  $(".stats-controls").click(function(){
    $(this).parent("li").toggleClass("selected");
    $(this).siblings(".hidden-stats").slideToggle("fast");
    return false;
  });

  activateControls();

  $(".new-performance-link").click(function() {
    $("#new-performance-row").show();
    return false;
  });

  $(".cancel-new-performance-link").click(function() {
    $("#new-performance-row").hide();
    return false;
  });

  $(".checkall").click(function(){
    var isChecked = $(this).is(":checked");
    $(this).closest('form').find("input[type='checkbox']:enabled").each(function(index, element){
      element.checked = isChecked;
      $(element).change();
    });
  });

  $(".zebra tbody").each(function(){
    zebra($(this));
  });

  $(".search-help-popup").dialog({autoOpen: false, draggable:false, modal:true, width:700, title:"Search help"});
  $("#search-help-link").click(function(){
    $(".search-help-popup").dialog("open");
    return false;
  });

  $(".add-new-ticket-type-link").bind("ajax:complete", function(et, e){
    $("#newTicketType").html(e.responseText);
    $("#newTicketType").modal( "show" );
    bindMemberTickets();
    bindLimitPopover();
    return false;
  });

  $("#bulk-action-link").bind("ajax:complete", function(et, e){
    $("#bulk-action-modal").html(e.responseText);
    $("#bulk-action-modal").modal( "show" );
    activateControls();
    return false;
  });

  $('.new-action-save').click(returnFalse())
  $('.action-type-button').click(function(){
    $('.new-action-save').off();
  })

  $(".new-action-link").click(function(){
    $('.new-action-form').toggle();
    return false;
  });

  $('.action-type button').click(function() {
    type = $(this).attr('data-action-type');
    form = $(this).parents('form');
    $('#action_type').val(type);
    $('#artfully_action_details').attr('placeholder', $(this).attr('data-details-placeholder'));
    $("#artfully_action_details").removeAttr("disabled");
    var subtypes = eval($(this).attr('data-subtypes'));
    $('#artfully_action_subtype').empty();

    if (subtypes.length > 0) {
      $('#artfully_action_subtype').show();
      $.each(subtypes, function(index, value) {
        $('#artfully_action_subtype')
          .append($("<option></option>")
          .attr("value",value)
          .text(value));
      });
    } else {
      $('#artfully_action_subtype').hide();
    }

    if (type === 'give') {
      form.find('.dollar-inputs').show();
    } else {
      form.find('.dollar-inputs').hide();
    }

    $('#artfully_action_details').focus();
    return true;
  })

  bindEditOrderLink()

  $(".edit-note-link").click(function(){
    $(this).parents('tr').find('td').hide();
    $(this).parents('tr').find('.edit-note-form').show();
    $(this).parents('tr').find('.edit-note-form textarea').focus();
    return false;
  });

  $(".new-note-link").click(function(){
    $('.new-note-form').toggle();
    $('.new-note-form textarea').focus();
    return false;
  });

  $('table#notes-list').on("click", 'td.toggle-truncated .truncated, td.toggle-truncated .not-truncated', function(event) {
    $(this).parent().find('.truncated,.not-truncated').toggle();
  })

  $('table#action-list').on("click", 'td.toggle-truncated .truncated, td.toggle-truncated .not-truncated', function(event) {
    $(this).parent().find('.truncated,.not-truncated').toggle();
    bindEditOrderLink()
  })

  $('table#action-list').on("click", 'a.edit-action-link', function(event) {
    event.stopPropagation(); // dont toggle truncated
    event.preventDefault();  // dont follow link
    $(this).parents('tr').find('td').hide();
    $(this).parents('tr').find('.edit-action-form').show();
    $(this).parents('tr').find('.edit-action-form textarea').focus();
  })

  $('.action-form').on("click", 'a.action-form-cancel-link', function(event) {
    $(this).parents('tr').find('td').show();
    $(this).parents('.action-form').hide();
    $(this).parents('.modal').modal( "hide" );
    return false;
  })

  $('#more-notes-link').toggle(function() {
    $('#more-notes').toggle();
    $('#more-notes-link .triangle').html('&#9662;');
  },
  function() {
    $('#more-notes').toggle();
    $('#more-notes-link .triangle').html('&#9656;');
  });

  var eventId = $("#calendar").attr("data-event");
  var resellerEventId = $("#calendar").attr("data-reseller-event");
  var organizationId = $("#calendar").attr("data-organization");
  if (eventId !== undefined) {
    $('#calendar').fullCalendar({
      height: 500,
      events: '/events/' + eventId + '.json',
      eventClick: function(calEvent, jsEvent, view){
        window.location = '/events/'+ eventId + '/shows/' + calEvent.id;
      }
    });
  } else if (resellerEventId !== undefined && organizationId !== undefined) {
    $('#calendar').fullCalendar({
      height: 500,
      events: '/organizations/' + organizationId + '/reseller_events/' + resellerEventId + '.json'
    });
  }
  $('#tabs').tabs({
      show: function(event, ui) {
          $('#calendar').fullCalendar('render');
      }
  });

  $('.tag.deletable').each(function() {
		createControlsForTag($(this));
  });

  $(".new-tag-form").bind("ajax:beforeSend", function(evt, data, status, xhr){
		tagText = validateTag()
    if(!tagText) { return false; }
    $(this).hide();
    newTagLi = $(document.createElement('li'));
		newTagLi.addClass('tag').addClass('deletable').addClass('rounder').html(tagText);
    $('.tags li:last').before(newTagLi);
    $('.tags li:last').before("\n");
		createControlsForTag(newTagLi);
    $('#new-tag-field').attr('value', '');

		bindControlsToListElements();
		bindXButton();
  });

  bindControlsToListElements();
  bindXButton();

  $(".delete").bind("ajax:beforeSend", function(evt, data, status, xhr){
    $(this).closest('.tag').remove();
  });

  $(".super-search").bind("ajax:complete", function(evt, data, status, xhr){
      $(".super-search-results").html(data.responseText);
      $(".super-search-results").removeClass("loading");
  }).bind("ajax:beforeSend", function(){
    $(".super-search-results").addClass("loading");
  });

  $('.editable .value').each(function(){
    var url = $(this).attr('data-url'),
        name = $(this).attr('data-name');

    $(this).editable(url, {
      method: "PUT",
      submit: "OK",
      cssclass: "jeditable form-inline",
      height: "15px",
      width: "150px",
      name: "person[" + name + "]",
      callback: function(value, settings){
        $(this).html(value[name]);
        $(this).trigger('done');
      },
      ajaxoptions: {
        dataType: "json"
      }
    });
  });

});



bindXButton = function() {
  $(".delete").bind("ajax:beforeSend", function(evt, data, status, xhr){
    $(this).closest('.tag').remove();
  });
};


validateTag = function() {
  var tagText = $('#new-tag-field').attr('value');
  if(!validTagText(tagText)) {
    $('.tag-error').text("Only letters, number, or dashes allowed in tags");
    return false;
  } else {
    $('.tag-error').text("");
    $('li.tag.new-tag').show();
    return tagText;
  }
}

/*
 * Validates alphanumeric and -
 */
validTagText = function(tagText) {
	var alphaNumDashRegEx = /^[0-9a-zA-Z-]+$/;
	return alphaNumDashRegEx.test(tagText);
};

createControlsForTag = function(tagEl) {
	var tagText = tagEl.html().trim();
	var subjectName = tagEl.parent("ul").attr('id').split("-")[0];
	var subjectId = tagEl.parent("ul").attr('id').split("-")[1];

	var deleteLink = '<a href="/'+subjectName+'/'+ subjectId +'/tag/'+ tagText +'" data-method="delete" data-remote="true" rel="nofollow">X</a>';
	var controlsUl =  $(document.createElement('ul')).addClass('controls');
	var deleteLi = $(document.createElement('li')).addClass('delete').append(deleteLink);

	controlsUl.append(deleteLi);

  tagEl.append(controlsUl);
	tagEl.append("\n");
};

function touchCurrency() {
  $(".currency").each(function(index, element){
		$(this).focus()
		$(this).maskMoney('mask')
	});
}

function activateControls() {
  $(".currency").each(function(index, element){
    var name = $(this).attr('name'),
        input = $(this),
        form = $(this).closest('form'),
        hiddenCurrency = $(document.createElement('input'));

    input.maskMoney({showSymbol:true, symbolStay:true, allowZero:true, symbol:"$"});
    input.attr({"id":"old_" + name, "name":"old_" + name});
    hiddenCurrency.attr({'name': name, 'type': 'hidden'}).appendTo(form);

    form.submit(function(){
      hiddenCurrency.val(Math.round( parseFloat(input.val().substr(1).replace(/,/,"")) * 100 ));
    });
  });

  $(".datepicker-alt-field" ).datepicker({
    dateFormat: 'yy-mm-dd',
    altField: '#ends_at'
  });
  $(".datepicker" ).datepicker({dateFormat: 'yy-mm-dd'});

	if (!Modernizr.inputtypes.date) {
		$('input[type="date"]').datepicker({
      dateFormat: 'yy-mm-dd'
    });
	}

  $('.datetimepicker').datetimepicker({dateFormat: 'yy-mm-dd', timeFormat:'hh:mm tt', ampm: true });
  if (!Modernizr.inputtypes.datetime) {
    $('input[type="datetime"],input[type="datetime-local"]').datetimepicker({
      dateFormat: 'yy-mm-dd',
      timeFormat:'hh:mm tt',
      ampm: true
    });
  }
	

}

function toggleVisibility(el) {
  el = $(el)
  vis = el.hasClass('invisible')
  if(vis) {
    el.removeClass('invisible')
  } else {
    el.addClass('invisible')
  }
}

function togglePrintPreview(){
    var screenStyles = $("link[rel='stylesheet'][media='screen']"),
        printStyles = $("link[rel='stylesheet'][href*='print']");

    if(screenStyles.get(0).disabled){
      screenStyles.get(0).disabled = false;
      printStyles.attr("media","print");
    } else {
      screenStyles.get(0).disabled = true;
      printStyles.attr("media","all");
  }
}

$('.btn-delete-preset-amount').live('click',function(){
    $(this).closest('tr').remove();
    return false;
});

$( ".btn-add-preset-amount" ).click(function() {
    $('#fixed_gift_error').empty();
    if($.isNumeric($('#input-preset-amount').val())) {
        $('#table-preset-amount tr').last().after(
                '<tr>' +
                    '<td>$' +
                        $('#input-preset-amount').val() +
                        '<input name=\"donation_preset[]\" type=\"hidden\" value=\"' + $('#input-preset-amount').val() +'">' +
                    '</td>' +
                    '<td><button class="btn-delete-preset-amount">Delete</button></td>' +
                '</tr>');
    } else {
        $('#fixed_gift_error').append($(document.createElement('div'))
            .addClass('error')
            .addClass('alert-error')
            .html('<span>Please enter a number!</span>'));
    }
    $('#input-preset-amount').val("");
    return false;
});

$( '#widget_type_donations' ).click(function() {
    $("#preset-amount").show();
    $("#widget-event").hide();
});
$( '#widget_type_event' ).click(function() {
    $("#preset-amount").hide();
    $("#widget-event").show();
});
$( '#widget_type_both' ).click(function() {
    $("#preset-amount").show();
    $("#widget-event").show();
});
