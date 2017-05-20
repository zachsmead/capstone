base_url = 'https://api.twitter.com/1.1/statuses/user_timeline.json'

auth = {
			'oauth_consumer_key' => ENV['TWITTER_CONSUMER_KEY'], 
			'oauth_nonce' => [*('a'..'z'),*('0'..'9')].shuffle[0,50].join,
			'oauth_signature_method' => 'HMAC-SHA1',
			'oauth_timestamp' => Time.now.to_i,
			'oauth_token' => ENV['TWITTER_ACCESS_TOKEN'],
			'oauth_version' => '1.0'	
		}