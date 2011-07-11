module ApplicationHelper
  def nav_bar(selected_category)

    music_class = art_class = theater_class = tech_class = today_class = ""

    case(selected_category)
    when :music
      music_class = "selected-odd"
    when :art
      art_class = "selected-even"
    when :theater
      theater_class = "selected-odd"
    when :tech
      tech_class = "selected-even"
    when :today
      today_class = "selected-odd"
    end

    n = <<-eos
	<div id="middle" style="margin-top: 0" class="clearfloat">
	
	<div id="cat-1" class="category #{music_class}">
				<span class="cat_title"><a href="/search?q=tag:music">Music</a></span>
		<a href="/search?q=tag:music"><p>Recommendations on what shows to check out</p> 
</a>
	</div>

	    	
	<div id="cat-2" class="category #{art_class}">
				<span class="cat_title"><a href="/search?q=tag:arts">Art</a></span>
		<a href="/search?q=tag:arts"><p>Stay tuned in on touring artists and the local art scene.</p> 
</a>
	</div>

	    	
	<div id="cat-3" class="category #{theater_class}">
				<span class="cat_title"><a href="/search?q=tag:theater">Performance</a></span>
		<a href="/search?q=tag:theater"><p>Stop here for previews of Seattle theatre, comedy and dance.</p> 
</a>
	</div>

	    	
	<div id="cat-4" class="category #{tech_class}">
				<span class="cat_title"><a href="/search?q=tag:text">Tech/Sci</a></span>
		<a href="/search?q=tag:tech"><p>Geek out at these tech and science related events.</p> 
</a>
	</div>

	    	
	<div id="cat-5" class="category #{today_class}">
				<span class="cat_title"><a href="/events">On the street</a></span>
		<a href="/events"><p>A little bit of everything Seattle has to offer.</p> 
</a>
	</div>

	    	
	</div>
    eos

    n.html_safe
  end

  def login_form
    if current_user
      ("Hi #{current_user.name}! | "+link_to("Logout", logout_url)).html_safe
    else
      link_to("Login or Sign up", login_url).html_safe
    end
  end

  def share_box id
    n = <<-eos
    <div class="cta-shares clearfloat">
      <div class="cta-share"><fb:like id="#{id}-fblike" href="fourthirtysix.com" send="false" layout="box_count" show_faces="false" font="arial"></fb:like></div>
      <div class="cta-share"><a href="http://twitter.com/share?count=vertical&url=<%=u (polymorphic_path event, :only_path => false) %>" class="twitter-share-button" data-count="horizontal" data-via="4thirtysix">Tweet</a></div>
      <div class="cta-share"><div id="#{id}-googleplusone"></div></div>
      <script type="text/javascript">
        gapi.plusone.render(document.getElementById("#{id}-googleplusone"), {"size": "tall", "count": "true"});
        /*FB.XFBML.parse(document.getElementById('foo'));*/
      (function(){
      var twitterWidgets = document.createElement('script');
      twitterWidgets.type = 'text/javascript';
      twitterWidgets.async = true;
      twitterWidgets.src = 'http://platform.twitter.com/widgets.js';
      document.getElementsByTagName('head')[0].appendChild(twitterWidgets);
    })();
      </script>
    </div>
    eos

    n.html_safe
  end
end
