// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
jQuery.ajaxSetup({  
    'beforeSend': function (xhr) {xhr.setRequestHeader("Accept", "text/javascript")}  
});

$(document).ready(function (){  
  $('#spotify-results').hide();
  $('#clickForSpotify').click(function (){
    $.get($(this).attr('action'), null, null, "script");
  $("#clickForSpotify").html("Creating ...");
  return false;  
  });  
});