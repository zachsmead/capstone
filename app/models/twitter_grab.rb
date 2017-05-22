require 'twitter'
load Rails.root + 'config/initializers/twitter.rb'

class TwitterGrab

	attr_accessor :twitter_client, :timeline

	def initialize # this initializes a TwitterGrab instance with an instance variable @twitter_client.
								 # @twitter_client is an instance of class Client in the Twitter::Rest namespace
		@twitter_client = Twitter::REST::Client.new do |config|
		  config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
		  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
		  config.access_token = ENV['TWITTER_ACCESS_TOKEN']
		  config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
		end

		# @timeline =  @twitter_client.user_timeline('sferik')
	end

	def collect_with_max_id(collection=[], max_id=nil, &block)
	  response = yield(max_id)
	  collection += response
	  response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
	end

	def get_all_tweets(user) # calls the method on the instance variable @twitter_client
	  collect_with_max_id do |max_id|
	    options = {count: 200, include_rts: true}
	    options[:max_id] = max_id unless max_id.nil?
	    @twitter_client.user_timeline(user, options)
	  end
	end

	def tweets_into_string(tweets) # takes an array of tweet objects and makes them 1 string for analysis
		output_string = ''

		tweets.each do |tweet|
			output_string += tweet.full_text
		end

		return output_string
	end

end