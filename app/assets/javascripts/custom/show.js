$(document).ready(function () {

  /***** Calendar for existing shows *****/

  var showCal = $('#show-calendar')
  showCal.fullCalendar({
    height: 500
    ,eventSources: [ 
      { 
        url: '/events/'+showCal.attr('data-event-id')+'.json', color: "#adadad"
        ,success: function(data) { 
          $.each(data, function (index, obj) {
            if(obj.state == "unpublished") {
              obj.color = "#ADADAD"
            } else {
              obj.color = "#33ADDD"
            }
          }) 
        } 
      } 

    ]      
    ,eventClick: function(ev, jsEvent, view) {
      window.location = "/events/" + ev.event_id + "/shows/" + ev.id
    }
  })

  /***** PICK DATES FOR NEW SHOW *****/

  var eventArray = new Array()
  var cal = $('#new-show-calendar')
  cal.fullCalendar({
      height: 400
      ,eventSources: [ { url: '/'+cal.attr('data-event-type')+'/'+cal.attr('data-event-id')+'.json', color: "#adadad" } ]
      ,events: eventArray
      ,dayClick: function(date, allDay, jsEvent, view) {
        var validShow = true
        var today = new Date()
        var hour = $('#show-time-hour').val()
        var minute = $('#show-time-minute').val()
        var meridian = $('#show-time-meridian').val()

        var hour24 = hour
        if (hour24 == "12") {
          hour24 = "0"
        }

        if (meridian == "p") {
          hour24 = (+hour24 + 12).toString()
        }
        date.setHours(hour24)
        date.setMinutes($('#show-time-minute').val())
        var stringDate = date.toString();
        e = { title: hour + ":" + minute + meridian, start: stringDate }

        //check if this show is scheduled in the past
        if(today > date) {
          validShow = false
        }

        //see if the event array has this time and date already
        $.each(eventArray, function(index, value) {
          if (value.start == stringDate) {
            validShow = false;
          }
        })

        if (validShow == true) {
          eventArray.push(e);
          cal.fullCalendar( 'renderEvent', e );
        }

      }
      ,eventClick: function(event, jsEvent, view) {
        if (eventArray.indexOf(event) > -1) {
          eventArray.splice(eventArray.indexOf(event), 1);
          cal.fullCalendar( 'removeEvents', event._id );
          eventArray = cal.fullCalendar( 'getEventSources' )[2].events
        }
      }
      ,viewRender: function(view, el) {
        $('#new-show-calendar .fc-today').prevAll('td').addClass('past-date');
        $('#new-show-calendar .fc-today').parent().prevAll().find('td').addClass('past-date');
      }
  })
  $('#new-show-calendar .fc-today').prevAll('td').addClass('past-date');
  $('#new-show-calendar .fc-today').parent().prevAll().find('td').addClass('past-date');

  /***** HANDLE FORM SUBMISSION *****/

  $('#new_show').on('submit', function() {
    $.each(eventArray, function(index, e) {
      $('#new_show').append($("<input>").attr("type", "hidden").attr("name", "show[datetime][]").val(e.start))
    })
  })

  /***** SPRITED BUTTONS *****/

  $("form.destroyable").on("ajax:before", function(){
		var row = $(this).closest("tr")
    row.remove();
  });

  $("form.destroyable").on("ajax:success", function(ev){
    setFlashMessage("The show has been deleted");
		ev.stopImmediatePropagation()
  });

  $("form.destroyable").on("ajax:error", function(ev){
    setErrorMessage("That show cannot be deleted");
		ev.stopImmediatePropagation()
  });

  $(".sprited").on("ajax:before", function(){
    $(this).find("input:submit").attr('disabled','disabled');
    $('.show-state').html("Loading...")
  });

  $(".sprited input:submit").on("click", function(event){
    var $dialog = $(this).siblings(".confirmation.dialog").clone(),
        $submit = $(this);

    if($dialog.length !== 0){
      event.preventDefault();
      event.stopImmediatePropagation();
      var $confirmation = $(document.createElement('input')).attr({type: 'hidden', name:'confirm', value: 'true'});

      $dialog.dialog({
        autoOpen: false,
        modal: true,
        buttons: {
          Cancel: function(){
            $submit.removeAttr('disabled');
            $dialog.dialog("close")
          },
          Ok: function(){
            $dialog.dialog("close")
            $submit.closest('form').append($confirmation);
            $submit.closest('form').submit();
            $confirmation.remove();
          }
        }
      });
      $dialog.dialog("open");
      return false;
    }
  });

  $(".sprited").on("ajax:success", function(xhr, show){
    var container = $(this).parents(".sprited-container");
    var sprited = $(".sprited-element", container)
    sprited.push(container)

    $.each(sprited, function () {
      $(this).find(":submit").removeAttr('disabled');
      $(this).removeClass("pending built published unpublished")
      $(this).addClass(show.state);
    }) 
    $('.show-state').html(show.state)
  });

  $(".sprited").on("ajax:error", function(xhr, status, error){
    var data;
    $('.show-state').html("Error")
    $(this).find(":submit").removeAttr('disabled');
  });
});
