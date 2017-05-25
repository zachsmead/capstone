class BooksController < ApplicationController

	def index
		if params[:liked] == 'self'
			@books = current_user.books
		else
			@books = Book.all
		end
	end

	def featured
		@followees = current_user.followees
	end

	def show
		@book = Book.find_by(id: params[:id])
		@number_of_likes = @book.users.length


		# @created_at = (Time.now - @book.created_at.to_time)/1.hour

		# this method .updates @book.analysis_url if it doesn't already have a value

		if !@book.analysis_url
			analysis_url = Nlu.store_analysis(@book)
			@book.update(analysis_url: analysis_url)
			redirect_to "/books/#{@book.id}"
		else
			stats = Nlu.analysis(@book)
			@emotions_summary = stats[:emotions_summary]
			@keywords = stats[:keywords]



			blank_keyword = {
					"text": "",
					"sentiment": {
						"score": 0
					},
					"relevance": 0,
					"emotion": {
						"sadness": 0,
						"joy": 0,
						"fear": 0,
						"disgust": 0,
						"anger": 0
					}
				}



			(5 - @keywords.length).times do # if the keywords json has less than 5, add blank keywords until it has 5
				@keywords << 'none'
			end



			@score = @emotions_summary['sentiment'].round(2)
			
			if @score < -0.30 
				@sentiment_word = 'Negative'
			elsif -0.30 <= @score && @score < -0.10
				@sentiment_word = 'Fairly negative'
			elsif -0.10 <= @score && @score < -0.07
				@sentiment_word = 'Slightly negative'
			elsif -0.07 <= @score && @score < 0.07
				@sentiment_word = 'Neutral'
			elsif 0.07 <= @score && @score < 0.10
				@sentiment_word = 'Slightly positive'
			elsif 0.10 <= @score && @score < 0.30
				@sentiment_word = 'Fairly positive'
			elsif @score >= 0.30
				@sentiment_word = 'Positive'
			end
		end

		if current_user
			@like_button = true
		else
			@like_button = false
		end


		
	end

	def new
	end

	def create
		
		# validations 
		# checks if there is a file or url present. uses hidden_field_tag :form_identifier in new.html.erb
		if params[:form_identifier] == "url"
			puts "Conditional URL identifier"
			if (params[:reddit_username] == "" && params[:twitter_username] == "")
				if params[:url] == ""
					puts "URL isnt here"
					flash[:danger] = "Please pick 1 url or username"
					redirect_to "/books/new"
					return
				end
			else
				if (params[:reddit_username] == "" && params[:twitter_username] == "")
					puts "username isnt here"
					flash[:danger] = "Please give 1 username or url"
					redirect_to "/books/new"
					return
				end
			end
		elsif params[:form_identifier] == "file"
			puts "Conditional File identifier"
			if params[:file] == nil
				puts "File not there"
				flash[:danger] = "Please choose 1 url, file or username"
				redirect_to "/books/new"
				return
			end
		end

		begin
			if params[:file] && params[:title] == "" # check for title. if there isn't one, make one.
				params[:title] = File.basename(params[:file].original_filename, '.txt').parameterize('_')
			elsif params[:url] && params[:url] != "" && params[:title] == "" # url was given
				if params[:url].starts_with?("https://www.reddit.com") || (params[:url].starts_with?("www.reddit.com") && params[:url].include?("/comments/"))
					webpage = Nokogiri::HTML(
						open(
							params[:url],
							"User-Agent" => "OpenBooks"
						) 
					)
					params[:title] = webpage.at('title').inner_text
				else
					begin
						webpage = Nokogiri::HTML(open params[:url])
						params[:title] = webpage.at('title').inner_text
					rescue
						flash[:error] = "The URL didn't give a response."
						redirect_to "/"
						return
					end
				end
			elsif params[:url] == "" && (params[:reddit_username] != "" || params[:twitter_username] != "")
				params[:title] = '/u/' + params[:reddit_username] if params[:reddit_username] != ""
				params[:title] = '@' + params[:twitter_username] if params[:twitter_username] != ""
			end
		rescue
			flash[:error] = "The title or URL was not acceptable"
			redirect_to "/"
			return
		end



		params[:card_title] = params[:title].truncate(27)



		if params[:file] # this means that a file was uploaded

			begin
				book_url = Book.s3_text_upload(params) # takes in params, stores text as s3 obj, returns a url for the obj
			rescue
				flash[:error] = "Upload failed."
				redirect_to "/"
				return
			end

			begin
				@book = Book.new(title: params[:title], card_title: params[:card_title], url: book_url)
				@book.save # save the book so it has an id when we pass it to the wordcount json builder

				book_json_url = Book.s3_text_upload_json(@book)

				@book.update(book_cloud_url: book_json_url)
			rescue
				flash[:error] = "The analysis failed for this text."
				redirect_to "/"
				return
			end

		elsif params[:url] && params[:url] != "" # this means that a webpage url was given

			begin
				title = params[:title]
				url = params[:url]
				fixed_url = Book.fix_url(url)

				@book = Book.new(title: title, card_title: params[:card_title], url: fixed_url)
				@book.save

				attributes = Book.s3_web_content_json(@book)

				@book.update(
					book_cloud_url: attributes[:book_cloud_url],
					scraped_content_url: attributes[:scraped_content_url]
				)
			rescue
				flash[:error] = "URL wordgrab failed."
				redirect_to "/"
				return
			end
		elsif params[:url] == "" # this means a reddit or twitter username was given
			if params[:twitter_username] != "" && params[:reddit_username] == ""

				begin 
					title = params[:title]
					twitter_username = params[:twitter_username]
					url = 'https://twitter.com/' + twitter_username
					@book = Book.new(
						title: title, 
						card_title: params[:card_title], 
						twitter_username: twitter_username
					)
					@book.save

					attributes = Book.s3_web_content_json(@book)

					@book.update(
						url: url,
						book_cloud_url: attributes[:book_cloud_url],
						scraped_content_url: attributes[:scraped_content_url]
					)
				rescue
					flash[:error] = "Twitter failed, probably because of a typo or the user doesn't exist."
					redirect_to "/"
					return
				end
			elsif params[:reddit_username] != "" && params[:twitter_username] == ""

				begin
					title = params[:title]
					reddit_username = params[:reddit_username]
					url = 'https://reddit.com/u/' + reddit_username
					@book = Book.new(
						title: title, 
						card_title: params[:card_title], 
						reddit_username: reddit_username)
					@book.save

					attributes = Book.s3_web_content_json(@book)

					@book.update(
						url: url,
						book_cloud_url: attributes[:book_cloud_url],
						scraped_content_url: attributes[:scraped_content_url]
					)
				rescue
					flash[:error] = "Reddit failed, probably because of a typo or the user doesn't exist."
					redirect_to "/"
					return
				end
			end
		end # end if statement
		
		if @book.save
			redirect_to "/books/#{@book.id}", success: 'File successfully uploaded'
		else
			flash.now[:notice] = 'There was an error'
			redirect_to "/books/new"
		end

	end

	

	def like
		book_id = params[:book_id]
		user_id = current_user.id

		puts "*" * 100
		puts params[:book_id]
		puts current_user.id
		puts "*" * 100

		# if current_user
		# 	begin
				if !BookLike.find_by(book_id: book_id, user_id: user_id)
					@book_like = BookLike.new(book_id: book_id, user_id: user_id)
					@book_like.save(book_id: book_id, user_id: user_id)
				end
		# 	rescue
		# 		p 'error'
		# 		flash[:error] = "You can't like books unless you are logged in."
		# 	end
		# end

	end

end
