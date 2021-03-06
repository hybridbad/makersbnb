$(document).ready(function() {
  var user = new User();

  $("#signup").click(function() {
    $("input[name=firstName], text").val("");
    $("input[name=lastName], text").val("");
    $("input[name=email], email").val("");
    $("input[name=password], password").val("");
    $("#alert").remove();
  });

  $("#submitCreate").click(function() {
    let firstName = $("#firstName").val();
    let lastName = $("#lastName").val();
    let email = $("#emailCreate").val();
    let password = $("#passwordCreate").val();

    let newUser = user.createUser(firstName, lastName, email, password);

    checkUserFields(newUser);
  });
});

function checkUserFields(newUser) {
  for (var key in newUser) {
    if (newUser.hasOwnProperty(key)) {
      if (newUser[key] == "") {
        $("#alertMessageSignUp").html(
          "<div class='alert', id='alert'> Please fill in all the fields </div>"
        );
        return;
      }
    }
  }

  if (isEmail(newUser.email) == false) {
    $("#alertMessageSignUp").html(
      "<div class='alert', id='alert'> Please check the email address format </div>"
    );
    return;
  }

  $.post("http://localhost:9292/users/new", newUser, function() {
    window.location.replace("/index");
  });
}

function isEmail(email) {
  var regex = /^([a-zA-Z0-9_.+-])+\@(([a-zA-Z0-9-])+\.)+([a-zA-Z0-9]{2,4})+$/;
  return regex.test(email);
}
