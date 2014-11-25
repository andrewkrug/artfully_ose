endlessScrollRequest = null;

$(document).ready(function() {

  if($('#endless-scroll-pagination').length) {
    $(window).scroll(function() {
      if(!endlessScrollRequest) {

        url = $('#endless-scroll-pagination .next_page a').attr('href');
        if ((url) && ($(window).scrollTop() > $(document).height() - $(window).height() - 150)) {
          $('#endless-scroll-pagination').addClass('loading');
          endlessScrollRequest = true;
          $.getScript(url)
                  .done(function(script, textStatus) {
                      endlessScrollRequest = false
                  })
                  .fail(function(jqxhr, settings, exception) {
                      endlessScrollRequest = false
                  });;
        } 
      }          
    })
    $(window).scroll();
  }
});