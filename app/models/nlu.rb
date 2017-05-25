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

		stats = {}

		query_results = Unirest.get(book.analysis_url).body

		if query_results['keywords']
			stats[:keywords] = query_results['keywords'][0..4]
			puts "*" * 100
			puts 'if was triggered'
			puts "*" * 100
		else # if the analysis was not performed, return blank objects
			puts "*" * 100
			puts 'else was triggered'
			puts "*" * 100
			stats[:keywords] = []
			stats[:emotions_summary] = emotions_summary
			return stats
		end

		if !query_results['entities']
			query_results['entities'] = []
		end


		if query_results['keywords']
			query_results['keywords'].each do | keyword | # loop through all keywords in the result
				
				if keyword['sentiment']
					if !emotions_summary['sentiment']					  # add up all the keywords' relevance-weighted sentiment
						emotions_summary['sentiment'] = keyword['sentiment']['score'] #* keyword['relevance']
					else
						emotions_summary['sentiment'] += keyword['sentiment']['score'] #* keyword['relevance']
					end
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
		end

		if query_results['entities']
			query_results['entities'].each do | entity | # loop through all entities in the result
				
				if entity['sentiment']
					if !emotions_summary['sentiment']					  # add up all the entities' relevance-weighted sentiment
						emotions_summary['sentiment'] = entity['sentiment']['score'] #* entity['relevance']
					else
						emotions_summary['sentiment'] += entity['sentiment']['score'] #* entity['relevance']
					end
				end


				if entity['emotion'] 													# if the entity has an emotion hash,
					entity['emotion'].each do | emotion, score | # add those up weighted by relevance
						if !emotions_summary[emotion]
							emotions_summary[emotion] = score #* entity['relevance']
						else
							emotions_summary[emotion] += score #* entity['relevance']
						end
					end
				end
			end # end query_results['entities'].each loop
		end


		# finally, average all the emotion scores
		emotions_summary.each do | emotion, score |
			emotions_summary[emotion] = (score / (query_results['keywords'].length + query_results['entities'].length))
		end

		# or express emotion scores as % total of the whole document
		# start by adding all the emotions up for a total score												
		(emotions_summary.reject {|emotion, score | emotion == 'sentiment' }).each do | emotion, score | 
			puts "*" * 100
			puts emotions_summary
			puts "*" * 100
			all_emotions_total += score
		end

		puts all_emotions_total

		(emotions_summary.reject {|emotion, score | emotion == 'sentiment' }).each do | emotion, score | # next, change the scores to their percent of the total
			emotions_summary[emotion] = ((score / all_emotions_total) * 100).round(2)
		end

		stats[:emotions_summary] = emotions_summary

		return stats

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