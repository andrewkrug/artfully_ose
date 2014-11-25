//= require_self
//
$(function(){

  function cleanJsonPerson(jsonPerson) {
    jsonPerson.first_name = ( jsonPerson.first_name == null ? "" : jsonPerson.first_name )
    jsonPerson.last_name = ( jsonPerson.last_name == null ? "" : jsonPerson.last_name )
    jsonPerson.email = ( jsonPerson.email == null ? "" : jsonPerson.email )
    jsonPerson.company_name = ( jsonPerson.company_name == null ? "" : jsonPerson.company_name )
    return jsonPerson
  }
  $(document).on('keyup.autocomplete', '.fields.individual-fields .individual-name-input', function(){
    var autocompleteField = this;
    $(this).autocomplete({
      html: true,
      minLength: 3,
      focus: function(event, person) {
        event.preventDefault()
      },
      source: function(request, response) {
        $.getJSON("/people?utf8=%E2%9C%93&type=Individual&commit=Search", { search: request.term }, function(people) {
          responsePeople = new Array();

          $.each(people, function (i, person) {
            person = cleanJsonPerson(person)
            responsePeople[i] =  "<div data-row='"+""+"' id='search-result-full-name'><span id='search-result-first-name'>"+ person.first_name +"</span> <span id='search-result-last-name'>"+ person.last_name +"</span></div>"
            responsePeople[i] += "<div id='search-result-email' class='search-result-details'>"+ person.email +"</div>"
            responsePeople[i] += "<div class='clear'></div>"
            responsePeople[i] += "<div id='search-result-company-name' class='search-result-details'>"+ person.company_name +"</div>"
            responsePeople[i] += "<div id='search-result-id'>"+person.id+"</div>"
          });
          response(responsePeople)
        });
      },

      select: function(event, item) {
        event.preventDefault()
        var personId = $(item.item.value).filter("#search-result-id").html()
        var personFirstName = $("#search-result-first-name", item.item.value).html()
        var personLastName = $("#search-result-last-name", item.item.value).html()

        var personLabel = personFirstName + " " +  personLastName
        $(this).val(personLabel)
        $(this).siblings('.individual-id').val(personId)
      },
      open: function() {
        $(this).removeClass("ui-corner-all").addClass("ui-corner-top")
      },
      close: function() {
        $(this).removeClass("ui-corner-top").addClass("ui-corner-all")
      }

    });

    // Ensure the autocomplete drop-down shows up in the modal and on this row
    $(this).autocomplete("widget").insertAfter($(this))
  });
});

