$(function() {
  var rootContainer = null;

  // donation kit configuration below

  if ((rootContainer = $('#edit-donation-kit')).length) {
    var nodeHtml = $('<div>').append($('.new-suggested-gift-container', rootContainer).clone()).html(),
        nodeIdx = parseInt(nodeHtml.match(/\[(\d+)\]/) ? RegExp.$1 : 0);

    $(document).on('click', '#edit-donation-kit .suggested-gift-remove', function() {
      if (confirm('Are you sure you want to remove this gift level?')) {
        $(this).parents('.suggested-gift-container').first().remove();
      }
    });

    $(document).on('click', '#edit-donation-kit .suggested-gift-add', function() {
      var lastNode = $('.new-suggested-gift-container').last(),
          amount = parseFloat($('input', lastNode).last().val()) || 0;

      console.log(lastNode, amount);

      if (amount) {
        nodeIdx += 1;

        setTimeout(function() {
          $('a', lastNode).html('Remove').removeClass('suggested-gift-add').addClass('suggested-gift-remove');
          var newHtml = nodeHtml.replace(/\[\d+]/g, '[' + nodeIdx + ']').replace(/_\d+_/g, '_' + nodeIdx + '_');
          lastNode.after(newHtml);
        }, 50);
      }
    })
  }
});
