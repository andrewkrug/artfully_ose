Array.prototype.unique = function() {
  var a = [],
      l = this.length,
      i, j;

  for(i = 0; i < l; i++) {
    for(j = i+1; j < l; j++) {
      if (this[i] === this[j]){
        j = ++i;
      }
    }
    a.push(this[i]);
  }
  return a;
};

$(document).ready(function(){
  var methods = {
    hideGroups: function(){
      $(".grouped-form").css('display', 'none');
    },

    findItems: function(){
      var items = [];
      $(".grouped-form form input:checkbox").each(function(){
          items.push($(this).attr('class'));
      });
      return items.unique();
    },

    enableCheckboxes: function(items){
      var $checkbox;

      $.each(items, function(index, id){
        $checkbox = $('#row_' + id + ' td:first-child input:checkbox')
        $checkbox.removeAttr('disabled');

        $checkbox.change(function(){
          $("." + id).attr("checked", $(this).is(":checked"));
          $(".grouped-form").find("input:submit").each(function(){
            var anyChecked = $(this).closest("form").find(":checkbox").is(":checked");
            if(anyChecked){
              $(this).removeAttr('disabled');
              $(this).trigger('onEnable');
            } else {
              $(this).attr('disabled','disabled');
              $(this).trigger('onDisable');
            }
          });
        });
      });
    },

    displayError: function(message){
      $(document.createElement('div')).addClass('flash error').html(message).prependTo($(".grouped-form-target"));
    },

    generateControls: function(){
      var controls = $(document.createElement('div')).addClass('table-controls btn-group');

      $(".grouped-form").find("input:submit").each(function(){
        var original = this,
            button = $(document.createElement('input')).attr({'type':'button', 'value':$(this).attr('value'), 'disabled':'disabled'}).addClass("btn");

        $(original).attr({'disabled':'disabled'})
                   .bind('onEnable', function(){
                     button.removeAttr('disabled');
                   })
                   .bind('onDisable', function(){
                     button.attr('disabled','disabled');
                   });

        button.click(function(){
          var hiddenCheckboxes = $(original).closest('form').find('input:checked'),
              visibleCheckboxes = $(this).closest('form').find('tbody input:checked');

          if(hiddenCheckboxes.length !== visibleCheckboxes.length){
            methods.displayError("Oops! Some of the items you have selected are not available for this operation.");
          } else {
            $(original).click();
          }
        });

        button.appendTo(controls);
      });

      controls.prependTo($(".grouped-form-target"));
    }
  };

  methods.hideGroups();
  methods.enableCheckboxes(methods.findItems());
  methods.generateControls();
  $(document).trigger('grouped-form-ready');
});
