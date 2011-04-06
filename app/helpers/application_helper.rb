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
				<span class="cat_title"><a href="/search?q=tag:theater">Performing Art</a></span>
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
end
