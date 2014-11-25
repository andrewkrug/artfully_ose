/*
 * Will look for and remove nulls from:
 *  first_name
 *  last_name
 *  email
 *  company_name
 */
function cleanJsonPerson(jsonPerson) {
  jsonPerson.first_name = ( jsonPerson.first_name == null ? "" : jsonPerson.first_name )
  jsonPerson.last_name = ( jsonPerson.last_name == null ? "" : jsonPerson.last_name )
  jsonPerson.email = ( jsonPerson.email == null ? "" : jsonPerson.email )
  jsonPerson.company_name = ( jsonPerson.company_name == null ? "" : jsonPerson.company_name )
  return jsonPerson
}

function updateModal() {
  if($(".picked-person-name").length > 0) {
    $(".picked-person-name").html($("input#person_first_name").val() + " " + $("input#person_last_name").val())
    $(".picked-person-email").html($("input#person_email").val())
  }
}

function updateSelectedPerson(personId, personFirstName, personLastName, personEmail) {
  $("input#person_id").val(personId)
  $("input#person_first_name").val(personFirstName)
  $("input#person_last_name").val(personLastName)
  $("input#person_email").val(personEmail)
  updateModal()
}

function clearNewPersonForm() {
  $("input#person_id").val("")
  $("input#person_first_name").val("")
  $("input#person_last_name").val("")
  $("input#person_email").val("")
}

$("document").ready(function(){

  $("#new_person").bind("ajax:success", function(xhr, person){
    $(this).removeClass('loading')
    $(this).find("input:submit").removeAttr('disabled');
    person = cleanJsonPerson(person)
    updateSelectedPerson(person.id, person.first_name, person.last_name, person.email)
    clearNewPersonForm()
  });

  $("#new_person").bind("ajax:error", function(xhr, status, error){
    $(this).find("input:submit").removeAttr('disabled');
    data = eval("(" + status.responseText + ")");
    $(this).removeClass('loading')
  });

  $("input", "#the-details").autocomplete({
    html: true,
    minLength: 3,
    focus: function(event, person) {
      event.preventDefault()
    },
    source: function(request, response) {
      $.getJSON("/people?utf8=%E2%9C%93&commit=Search", { search: request.term }, function(people) {
        responsePeople = new Array();

        $.each(people, function (i, person) {
          person = cleanJsonPerson(person)
          responsePeople[i] =  "<div id='search-result-full-name'><span id='search-result-first-name'>"+ person.first_name +"</span> <span id='search-result-last-name'>"+ person.last_name +"</span></div>"
          responsePeople[i] += "<div id='search-result-email' class='search-result-details'>"+ person.email +"</div>"
          responsePeople[i] += "<div class='clear'></div>"
          responsePeople[i] += "<div id='search-result-company-name' class='search-result-details'>"+ person.company_name +"</div>"
          responsePeople[i] +=  "<div id='search-result-id'>"+person.id+"</div>"
        });
        response(responsePeople)
      });
    },
    select: function(event, person) {
      event.preventDefault()
      var personId         = $(person.item.value).filter("#search-result-id").html()
      var personFirstName  = $("#search-result-first-name", person.item.value).html()
      var personLastName   = $("#search-result-last-name", person.item.value).html()
      var personEmail      = $(person.item.value).filter("#search-result-email").html()

      updateSelectedPerson(personId, personFirstName, personLastName, personEmail)
    }
  });
});
