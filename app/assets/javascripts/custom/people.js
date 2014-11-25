String.prototype.startsWith = function(str)
{return (this.match("^"+str)==str)}

$(document).ready(function() {
  $("#communication-preference input[type=checkbox]").on("click", function(event) {
    $("#communication-preference input[type=submit]").removeClass("hidden");
  });

  $("#subscription-listing input[type=checkbox]").on("click", function(event) {
    $("#subscription-listing input[type=submit]").removeClass("hidden");
  });

  $("#person_do_not_call").on("click", function(event) {
    $lists = $(".mail-chimp-list");
    if ($(this).attr("checked") != "checked") {
      $lists.attr("disabled", false);
    } else {
      $lists.attr("checked", false);
      $lists.attr("disabled", true);
    }
  });

  $("input[type=checkbox].mail-chimp-list").on("click", function(event) {
    $target = $(event.target);

    if ($target.attr("checked") != "checked") {
      return;
    }

    event.preventDefault();
    $("#subscribe-modal").modal();
    $("#subscribe-modal .btn-primary").on("click", function(e) {
      $(event.target).attr("checked", "checked");
      $("#subscribe-modal").modal('hide');
    });
  });
  
  var is_star = function(htmlElement) {
    return (htmlElement === "\u272D");
  };

  $(".delete-confirm-link").bind("click", function(event){
    var $dialog = $(this).siblings(".confirmation.dialog").clone(),
        $submit = $(this);

    if($dialog.length !== 0){
      event.preventDefault();
      event.stopImmediatePropagation();
      var $confirmation = $(document.createElement('input')).attr({type: 'hidden', name:'confirm', value: 'true'});
    	var targetUrl = $(this).attr("href");
			var row = $(this).closest("tr")
			var table = row.closest("table")
			var dataTable = table.dataTable()

      $dialog.dialog({
        autoOpen: false,
        modal: true,
        buttons: {
          Cancel: function(){
            $dialog.dialog("close")
          },
          Ok: function(){
            $dialog.dialog("close")
						dataTable.fnDeleteRow( dataTable.fnGetPosition(row.get(0)) );
    				zebra($('.zebra'));
            $.post(targetUrl, {_method:'delete'},
               function(data) {
                 setFlashMessage("The note has been deleted");
               }
            );
          }
        }
      });
      $dialog.dialog("open");
      return false;
    }
  });

  $(".starable").on('click', function() {
    var star      = $.trim($(this).html()),
        person_id = $(this).attr("data-person-id"),
        type      = $(this).attr("data-type"),
        id        = $(this).attr("data-action-id"),
        this_table = $(this).parents('table'),
        this_row   = $(this).parents('tr');

    $.ajax({
       type: "POST",
       url: "/people/" + person_id + "/star/" + type + "/" + id
    });

    if($(this).hasClass('active')) {
      $(this).addClass('not-active');
      $(this).removeClass('active');
      $(this).trigger("unstarred");
    } else {
      $(this).removeClass('not-active');
      $(this).addClass('active');
      $(this).trigger("starred");
    }

    //and re-zebra the table
    zebra(this_table);
  });

  $(".relationship_starred").click(function() {
    var star      = $.trim($(this).html()),
        person_id = $(this).attr("data-person-id"),
        type      = $(this).attr("data-type"),
        id        = $(this).attr("data-action-id"),
        relationship_type  = $.trim($('.relationship_type',this.parent).html()),
        name               = $.trim($('.relationship_person',this.parent).html()),
        relationships_list = $('#key_relationships');

    if(is_star(star)) {
      relationships_list.append("<li id='"+id+"'><div class='key'>"+relationship_type+"</div><div class='value'>"+name+"</div></li>");
    } else {
      $(('#'+id), relationships_list).remove();
    }
  });

  function generateLink(field, $link){
    var href = $(field).html();

    if("Click to edit" !== href && "" !== href){
      $link.html("[ &#9656; ]").attr('target','_blank').appendTo($(field).parent());

      $link.hover(function(){
        if(!href.startsWith("http://")){
          href = "http://" + href;
        }
        $(this).attr("href", href);
      });
    }
  }

  $(".website.value").each(function(){
    var $link = $(document.createElement('a')),
        field = this;

    generateLink(field, $link);

    $(this).bind('done', function(){
      $link.remove();
      generateLink(field, $link);
    });
  });

  $("#mailing-address-form").hide();
  $("#create-mailing-address, #update-mailing-address").bind("click", function(){
    $("#mailing-address").hide();
    $("#mailing-address-form").show();
    $(this).hide();
    return false;
  });

  $("#cancel").bind("click", function(){
    $("#mailing-address-form").hide();
    $("#mailing-address").show();
    $("#create-mailing-address, #update-mailing-address").show();
    return false;
  });
  
  $('#edit_link').click(function(){
    dayDropDownValue.call(this);
    yearDropDownValue.call(this);
    dayValueForSelect.call(this);
    yearValueForSelect.call(this);
  });
  
  $('#birth_month').change(function(){
    dayDropDownValue.call(this);
  });
});

function yearDropDownValue(){
  var year_now = getYear();
  var yearsAsString = "";
  
  for(var i = 1920; i <= year_now; i++) {
    yearsAsString += "<option value='" + i + "'>" + i + "</option>";
  }
  
  $('#birth_year').html("<option value=''></option>");
  $('#birth_year').append(yearsAsString);
}

function dayDropDownValue(){
  var month = $('#birth_month').val();
  var year = $('#birth_year').val();
  var num_days = daysInMonth(month, 2012);
  var days_range = range(1,num_days + 1);
  var daysAsString = "";
  
  for(var i = 1; i < days_range.length; i++) {
    daysAsString += "<option value='" + days_range[i] + "'>" + days_range[i] + "</option>";
  }
  
  $('#birth_day').html("<option value=''></option>");
  $('#birth_day').append(daysAsString);
}

function yearValueForSelect(){
  var birth_year = $('div.year').data('person-birth_year');
  $('#birth_year').val(birth_year);
}

function dayValueForSelect(){
  var birth_day = $('div.day').data('person-birth_day');
  $('#birth_day').val(birth_day);
}

function daysInMonth(month,year) {
  return new Date(year, month, 0).getDate();
}

function getYear(){
  return new Date().getFullYear();
}

function range(start,num){
  return Array.apply(start, Array(num)).map(function (_, i) {return i;});
}
