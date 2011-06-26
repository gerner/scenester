// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function() { $('div.pill').corner(); });

var loadedPillId=null;
var loadedPillContent=null;
function loadPill(pillId, pillURL) {
    if(null != loadedPillId) {
        $("#"+loadedPillId).html(loadedPillContent);
        $("#"+loadedPillId).removeClass("clearpill");
        $("#"+loadedPillId).addClass("pillbox");
    }
    loadedPillContent=$("#"+pillId).html()
    loadedPillId=pillId;
    $("#"+pillId).load(pillURL, function() { $(".rest_in_place").rest_in_place();});
    $("#"+pillId).removeClass("pillbox");
    $("#"+pillId).addClass("clearpill");
    $(".rest_in_place").rest_in_place();
}
