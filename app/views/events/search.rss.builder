xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Events"
    #xml.description "Lots of articles"
    #xml.link formatted_articles_url(:rss)
    
    for event in @events
      xml.item do
        xml.title event.title_with_venue
        xml.description "foo"
        #xml.pubDate article.created_at.to_s(:rfc822)
        xml.link event.url
        xml.guid event.url
      end
    end
  end
end
