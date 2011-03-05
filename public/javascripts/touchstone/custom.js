//Flickr Widget in Sidebar			

$(document).ready(function(){		 			   
	// Our very special jQuery JSON fucntion call to Flickr, gets details of the most recent images			   
	$.getJSON("http://api.flickr.com/services/feeds/photos_public.gne?id=52617155@N08&lang=en-us&format=json&jsoncallback=?", displayImages);   //YOUR IDGETTR GOES HERE
	function displayImages(data) {																																   
		// Randomly choose where to start. A random number between 0 and the number of photos we grabbed (20) minus  7 (we are displaying 7 photos).
		var iStart = Math.floor(Math.random()*(0));	
		
		// Reset our counter to 0
		var iCount = 1;								
		
		// Start putting together the HTML string
		var htmlString = "<ul>";					
		
		// Now start cycling through our array of Flickr photo details
		$.each(data.items, function(i,item){
									
			// Let's only display 6 photos (a 2x3 grid), starting from a the first point in the feed				
			if (iCount > iStart && iCount < (iStart + 7)) {
				
				// I only want the ickle square thumbnails
				var sourceSquare = (item.media.m).replace("_m.jpg", "_s.jpg");		
				
				// Here's where we piece together the HTML
				htmlString += '<li><a href="' + item.link + '" target="_blank">';
				htmlString += '<img src="' + sourceSquare + '" alt="' + item.title + '" title="' + item.title + '"/>';
				htmlString += '</a></li>';
			}
			// Increase our counter by 1
			iCount++;
		});		
		
	// Pop our HTML in the #images DIV	
	$('#images').html(htmlString + "</ul>");
	
	// Close down the JSON function call
	}
	
// The end of our jQuery function	
});


//Flickr Widget in Footer			

$(document).ready(function(){		 			   
	// Our very special jQuery JSON fucntion call to Flickr, gets details of the most recent images			   
	$.getJSON("http://api.flickr.com/services/feeds/photos_public.gne?id=52617155@N08&lang=en-us&format=json&jsoncallback=?", displayImages);  //YOUR IDGETTR GOES HERE
	function displayImages(data) {																																   
		// Randomly choose where to start. A random number between 0 and the number of photos we grabbed (20) minus  7 (we are displaying 7 photos).
		var iStart = Math.floor(Math.random()*(0));	
		
		// Reset our counter to 0
		var iCount = 1;								
		
		// Start putting together the HTML string
		var htmlString = "<ul>";					
		
		// Now start cycling through our array of Flickr photo details
		$.each(data.items, function(i,item){
									
			// Let's only display 6 photos (a 2x3 grid), starting from a the first point in the feed				
			if (iCount > iStart && iCount < (iStart + 10)) {
				
				// I only want the ickle square thumbnails
				var sourceSquare = (item.media.m).replace("_m.jpg", "_s.jpg");		
				
				// Here's where we piece together the HTML
				htmlString += '<li><a href="' + item.link + '" target="_blank">';
				htmlString += '<img src="' + sourceSquare + '" alt="' + item.title + '" title="' + item.title + '"/>';
				htmlString += '</a></li>';
			}
			// Increase our counter by 1
			iCount++;
		});		
		
	// Pop our HTML in the #images DIV	
	$('#imagesfooter').html(htmlString + "</ul>");
	
	// Close down the JSON function call
	}
	
// The end of our jQuery function	
});


//Lightbox Code
$(document).ready(function() { 
	$("a.fancylightbox").fancybox({
		'titleShow'     : true,
		'titlePosition'	: 'over',
		'transitionIn'	: 'fade',
		'transitionOut'	: 'fade',
		'overlayOpacity': '0.5',
		'overlayColor'  :  '#333'
	});
	$("a.buttonfancylightbox").fancybox({
		'titleShow'     : true,
		'titlePosition'	: 'over',
		'transitionIn'	: 'fade',
		'transitionOut'	: 'fade',
		'overlayOpacity': '0.5',
		'overlayColor'  :  '#333'
	});
	$("a.fancylightboxnorollover").fancybox({
		'titleShow'     : true,
		'titlePosition'	: 'over',
		'transitionIn'	: 'fade',
		'transitionOut'	: 'fade',
		'overlayOpacity': '0.5',
		'overlayColor'  :  '#333'
	});
	$("a[rel=portfolio]").fancybox({
		'titleShow'     : true,
		'titlePosition'	: 'over',
		'transitionIn'	: 'elastic',
		'transitionOut'	: 'elastic',
		'overlayOpacity': '0.5',
		'overlayColor'  :  '#333'
	});
	$(".videolightbox").fancybox({
		'titleShow'     : false,
		'transitionIn'		: 'fade',
		'transitionOut'		: 'fade',
		'type'				: 'iframe',
		'overlayOpacity': '0.5',
		'overlayColor'  :  '#333'
	});
	$(".buttonvideolightbox").fancybox({
		'titleShow'     : false,
		'transitionIn'		: 'fade',
		'transitionOut'		: 'fade',
		'type'				: 'iframe',
		'overlayOpacity': '0.5',
		'overlayColor'  :  '#333'
	});
});

//Transparency Adjustments
$(document).ready(function() {  
            $('.transparent').each(function() {
                $(this).hover(
                    function() {
                        $(this).stop().animate({ opacity: 0.5 }, 400);
                    },
                   function() {
                       $(this).stop().animate({ opacity: 1.0 }, 400);
                   })
                });
});


//Start of Overlay Icons
$(document).ready(function(){   
    $("a.fancylightbox").append("<span></span>"); 
    $("a.fancylightbox").hover(function(){ 
        $(this).children("span").stop(true, true).fadeIn(0); 
    },function(){ 
        $(this).children("span").stop(true, true).fadeOut(0); 
    }); 
});
$(document).ready(function(){ 
    $("a.videolightbox").append("<span></span>"); 
    $("a.videolightbox").hover(function(){ 
        $(this).children("span").stop(true, true).fadeIn(0); 
    },function(){ 
        $(this).children("span").stop(true, true).fadeOut(0); 
    }); 
});
$(document).ready(function(){ 
    $("a.blogpost").append("<span></span>"); 
    $("a.blogpost").hover(function(){ 
        $(this).children("span").stop(true, true).fadeIn(0); 
    },function(){ 
        $(this).children("span").stop(true, true).fadeOut(0); 
    }); 
});