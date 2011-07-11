// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function() { $('div.pill').corner(); });

var loadedPillId=null;
var loadedPillContent=null;

function unloadPill2(pillId) {
    if(null != pillId) {
        $("#"+pillId).html(loadedPillContent);
        $("#"+pillId).removeClass("clearpill");
        $("#"+pillId).addClass("pillbox");
    }
}

function loadPill2(pillId, pillURL) {
    unloadPill(loadedPillId);
    loadedPillContent=$("#"+pillId).html()
    loadedPillId=pillId;
    $("#"+pillId).load(pillURL, function() { $(".rest_in_place").rest_in_place();});
    $("#"+pillId).removeClass("pillbox");
    $("#"+pillId).addClass("clearpill");
    $(".rest_in_place").rest_in_place();
}

var pillBorder;
var pillHeight;
var pillMargin;

function unloadPill(pillId) {
    if(null == pillId) {
        return;
    }
    pPillId = "#"+pillId+" .pill";
    $("#"+pillId+"-content").remove();
    $(pPillId).uncorner().corner().css("border", pillBorder).height(pillHeight).css("margin", pillMargin);
}

function formatPill(pillId) {
    $("#"+pillId+"-content").corner().css("border-color", $("#"+pillId+" .pill").css("background-color"));
    pPillId = "#"+pillId+" .pill";
    pillBorder = $(pPillId).css("border");
    pillHeight = $(pPillId).height();
    pillMargin = $(pPillId).css("margin");
    $(pPillId).uncorner().corner("top").css("border-bottom", "none").height(pillHeight+5).css("margin-bottom", "-1px");
}

function loadPill(pillId, pillURL) {
    unloadPill(loadedPillId);
    if(pillId == loadedPillId) {
        loadedPillId = null;
        return;
    }

    loadedPillId=pillId;
    $("#"+pillId).after("<div id=\""+pillId+"-content\" class=\"pillcontent clear\"></div>");
    formatPill(pillId);
    
    $("#"+pillId+"-content").load(pillURL, function() { $(".rest_in_place").rest_in_place();});
}
