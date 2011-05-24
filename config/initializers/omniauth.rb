if Rails.env == "production"
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
    provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
    provider :foursquare, ENV['FOURSQUARE_KEY'], ENV['FOURSQUARE_SECRET']
  end
else
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :twitter, 'RsWS1vSD0Dhfyo7qfCZF6w', 'PR8OKXz8qumiY6IZf4btxkcswpzph6lrOAwdPLxcs'
    provider :facebook, '61b9cfe8ca576b4b0bbc90b172d4da25', '10b0c17bfae1f4b8ac814a84299a282c'
    provider :foursquare, 'RPB4EENJOL3FSOZVKYZSOHS1034IIDYQJM5VCGIIZEBWWOA1', 'LGYDXOYGPTUNJZJ2G3SJ10VFTXLRACTM4FNPQB4QW0PQNWGS'
  end
end
