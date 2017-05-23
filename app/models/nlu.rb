class Nlu # Natural Language Understanding
	def self.analysis(book) # this method grabs the stored nlu analysis json and turns it into another json
															# which sums or averages all the elements from that json.
		emotions_summary = {
			'sentiment' => 0,
			'sadness' => 0,
			'joy' => 0,
			'fear' => 0,
			'disgust' => 0,
			'anger' => 0
		}
		all_emotions_total = 0

		query_results = Unirest.get(book.analysis_url).body

		query_results['keywords'].each do | keyword | # loop through all keywords in the result
			if !emotions_summary['sentiment']					  # add up all the keywords' un-relevance-weighted sentiment
				emotions_summary['sentiment'] = keyword['sentiment']['score'] #* keyword['relevance']
			else
				emotions_summary['sentiment'] += keyword['sentiment']['score'] #* keyword['relevance']
			end


			if keyword['emotion'] 													# if the keyword has an emotion hash,
				keyword['emotion'].each do | emotion, score | # add those up weighted by relevance
					if !emotions_summary[emotion]
						emotions_summary[emotion] = score #* keyword['relevance']
					else
						emotions_summary[emotion] += score #* keyword['relevance']
					end
				end
			end
		end # end query_results['keywords'].each loop


		# finally, average all the emotion scores
		emotions_summary.each do | emotion, score | 
			emotions_summary[emotion] = (score / query_results['keywords'].length)
		end

		# or express emotion scores as % total of the whole document
		# start by adding all the emotions up for a total score												
		(emotions_summary.reject {|emotion, score | emotion == 'sentiment' }).each do | emotion, score | 
			all_emotions_total += score
		end

		(emotions_summary.reject {|emotion, score | emotion == 'sentiment' }).each do | emotion, score | # next, change the scores to their percent of the total
			emotions_summary[emotion] = ((score / all_emotions_total) * 100).round(2)
		end

		return emotions_summary

	end # end method self.nlu_analysis

	def self.store_analysis(book)
		# api_location = "https://gateway.watsonplatform.net/natural-language-understanding/api/v1/analyze?version=2017-02-27"
		api_location = "https://watson-api-explorer.mybluemix.net/natural-language-understanding/api/v1/analyze?version=2017-02-27"
		
		if book.scraped_content_url
			read_location = "&url=" + book.scraped_content_url 
		else
			read_location = "&url=" + book.url 
		end

		api_params = "&features=keywords,entities&entities.emotion=true&entities.sentiment=true&keywords.emotion=true&keywords.sentiment=true"
		
		full_query = api_location + read_location + api_params

		# puts full_query

		query_results = Unirest.get(full_query,	
			auth: {:user => ENV['NLU_USERNAME'], :password => ENV['NLU_PASSWORD']}, 
			headers: { "Accept" => "application/json"}
			# parameters: [
			# 	# url: 'https://s3-us-west-1.amazonaws.com/projectgutenbergtest/books/alice_in_wonderland.txt'
			# 	# features: {:concepts => {:limit => 8}, :emotions => true}
			# ]
		).body.to_json

		analysis_json = S3_BUCKET.objects.create(
			"analysis/" + book.title.parameterize('_') + '_' + book.id.to_s + '.json', query_results
		)
		analysis_json.acl = :public_read

		return analysis_json.public_url
	end
end