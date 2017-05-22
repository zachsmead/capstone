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

		# this method .updates @book.analysis_url if it doesn't already have a value

		if !@book.analysis_url
			analysis_url = Nlu.store_analysis(@book)
			Book.update(analysis_url: analysis_url)
			redirect_to "/books/#{@book.id}"
		else
			@emotions_summary = Nlu.analysis(@book)
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
					flash[:danger] = "Please pick a url or file"
					redirect_to "/books/new"
					return
				end
			else
				if (params[:reddit_username] == "" && params[:twitter_username] == "")
					puts "username isnt here"
					flash[:danger] = "Please give a username or url"
					redirect_to "/books/new"
					return
				end
			end
		elsif params[:form_identifier] == "file"
			puts "Conditional File identifier"
			if params[:file] == nil
				puts "File not there"
				flash[:danger] = "Please choose a url or file"
				redirect_to "/books/new"
				return
			end
		end

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
				webpage = Nokogiri::HTML(open params[:url])
				params[:title] = webpage.at('title').inner_text
			end
		elsif params[:url] == "" && (params[:reddit_username] != "" || params[:twitter_username] != "")
			params[:title] = '/u/' + params[:reddit_username] if params[:reddit_username] != ""
			params[:title] = '@' + params[:twitter_username] if params[:twitter_username] != ""
		end



		params[:card_title] = params[:title].truncate(27)



		if params[:file] # this means that a file was uploaded
			book_url = Book.s3_text_upload(params) # takes in params, stores text as s3 obj, returns a url for the obj

			@book = Book.new(title: params[:title], card_title: params[:card_title], url: book_url)
			@book.save # save the book so it has an id when we pass it to the wordcount json builder

			book_json_url = Book.s3_text_upload_json(@book)

			@book.update(book_cloud_url: book_json_url)

		elsif params[:url] && params[:url] != "" # this means that a webpage url was given
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
		elsif params[:url] == "" # this means a reddit or twitter username was given
			if params[:twitter_username] != "" && params[:reddit_username] == ""
				title = params[:title]
				twitter_username = params[:twitter_username]
				url = 'https://twitter.com/' + twitter_username

				@book = Book.new(
					title: title, 
					card_title: params[:card_title], 
					twitter_username: twitter_username)
				@book.save

				attributes = Book.s3_web_content_json(@book)

				@book.update(
					url: url,
					book_cloud_url: attributes[:book_cloud_url],
					scraped_content_url: attributes[:scraped_content_url]
				)
			elsif params[:reddit_username] != "" && params[:twitter_username] == ""
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

		if !BookLike.find_by(book_id: book_id, user_id: user_id)
			@book_like = BookLike.create(book_id: book_id, user_id: user_id)
		end

	end

end
