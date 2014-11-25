$(function () {

  $("#upload-form").submit(function () {
    var filename = $("input[type=file]").val();
    if (filename === "") {
      alert("Please specify a file to upload.");
      return false;
    }
  });

});
