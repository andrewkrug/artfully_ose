//
// Service for keeping track of which memberships are selected
//

angular.module('artfully').factory('membershipSelections', function() {
  // Map of selected membership ids
  var map = {};

  // Initial values
  $('input[name=membership_ids\\[\\]]:checked').each(function(i,input) { map[input.value] = true });

  // Watch for changes
  $('body').on('change', 'input[name=membership_ids\\[\\]]', function(change) {
    var e = $(change.target);
    var membership_id = e.val();

    if ($(e).prop( "checked" )) {
      // Add the membership id if it's not already in the list
      var row   = e.closest('tr');
      var type  = $(row.find('.item-description')[0]);
      var price = $(row.find('.price')[0]);

      if (map[membership_id] === undefined) {
        map[membership_id] = {
          id: membership_id,
          type: type.text(),
          price: price.text()
        };
      }

    } else {
      // Remove the membership id
      delete map[membership_id];
    }
  });

  return map;
});

//
// Controller
//

angular.module('artfully').controller('MembershipActionsCtrl', ['$scope', 'membershipSelections', function($scope, membershipSelections) {
  $scope.loading      = false;
  $scope.error        = false;
  $scope.errorMessage = '';

  $scope.checkSelected = function() {
    $scope.error = false;
    $scope.errorMessage = '';

    if (Object.keys(membershipSelections).length == 0 ) {
      $scope.error = true;
      $scope.errorMessage = "Select one or more memberships.";
      return false;
    }
    return true;
  }

  $scope.change = function(click) {
    click.preventDefault();

    if (!$scope.checkSelected()) {
      return false;
    }

    // Open the modal
    $('#change').modal('show');
    return false;
  }

  $scope.cancel = function(click) {
    click.preventDefault();

    if (!$scope.checkSelected()) {
      return false;
    }

    $scope.loading = true;

    // Get membership_cancellations/new (fetches and displays the modal)
    $.ajax({
      url: 'membership_cancellations/new.js',
      data: {membership_ids: Object.keys(membershipSelections)},
      dataType: 'script',
      success: function (script, status, xhr) {
        $scope.$apply(function() {
          $scope.loading = false;
        });
      },
      error: function (xhr, text, error) {
        $scope.$apply(function() {
          $scope.loading = false;
          $scope.error = true;

          var message = error;
          if (xhr &&
            xhr.responseText !== undefined &&
            xhr.responseText != '' &&
            xhr.responseText != ' ') {
            message = xhr.responseText;
          }
          $scope.errorMessage = message;
        });
      }
    });
  }

}]);

angular.module('artfully').controller('ChangeMembershipController', ['$scope', 'membershipSelections', function($scope, membershipSelections) {

  // Template variables
  $scope.payment_method = '';
  $scope.price          = 0;
  $scope.total          = '$0.00';
  $scope.selected       = {};

  // Helpers
  $scope.comped = function() {
    return !!('' == $scope.payment_method || 'comp' == $scope.payment_method);
  }

  $scope.updateTotal = function() {
    var price = parseFloat($scope.price.substr(1).replace(/,/, ""));
    var total = (Object.keys($scope.selected).length * price);

    $scope.total = '$'+total.toFixed(2);
  }

  // Update the list of selected ids when the modal is shown
  $("#change").on('shown', function(shown) {
    $scope.selected = membershipSelections;

    // Mask the price field
    touchCurrency();
  });

  // Clear the list of selected ids when the modal is hidden
  $("#change").on('hidden', function(hidden) {
    $scope.payment_method = '';
    $scope.price = 0;
    $scope.updateTotal();
    $scope.selected = {};

    // Reset the form
    var form = $(this).find('form')[0];
    if (form) { form.reset(); }
  });
}]);

