class Reddit
	def self.start_comment_recursion(url) # get the main comment and start recursively grabbing comments

		input = Unirest.get(url + '.json').body
		output_string = ""

		if input['error']
			return input['error']
		end

		if input[0]["data"]["children"][0]["data"]["selftext"]
			self_post = input[0]["data"]["children"][0]["data"]["selftext"]
			output_string += self_post
		end

		output_string += Reddit.comments(input[1]["data"]["children"])

		return output_string
	end

	def self.comments(comment_array)
		local_string = ""

		comment_array.each do |comment|
			local_string += (comment["data"]["body"] + " ") if comment["data"]["body"]

			if comment["data"]["replies"] && !(comment["data"]["replies"].empty?)
				local_string += Reddit.comments(comment["data"]["replies"]["data"]["children"])
			end
		end

		return local_string
	end

	def self.grab_user_comments(username, next_page) # recursively grab all user comments
		comment_json = Unirest.get(
			'https://reddit.com/u/' + username + '/comments.json?sort=top&count=200&after=' + next_page
		).body


		comment_array = comment_json['data']['children']

		comment_counter = 0
		output_string = ""

		comment_array.each do |comment|
			output_string += comment['data']['body'] + ' '
		end

		if comment_json['data']['after']
			output_string += Reddit.grab_user_comments(username, comment_json['data']['after'])
		end

		return output_string

	end
end