class BooksController < ApplicationController

	def index
		if params[:liked]
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

		api_location = "https://gateway.watsonplatform.net/natural-language-understanding/api/v1/analyze?version=2017-02-27"
		read_location = "&url=https://s3-us-west-1.amazonaws.com/projectgutenbergtest/books/"
		title = "alice_in_wonderland.txt"
		api_params = "&features=keywords,entities&entities.emotion=true&entities.sentiment=true&keywords.emotion=true&keywords.sentiment=true"
		full_query = api_location + read_location + title + api_params

		
		# @test = Unirest.get(full_query,	
		# 	auth: {:user => ENV['NLU_USERNAME'], :password => ENV['NLU_PASSWORD']}, 
		# 	headers: { "Accept" => "application/json"}
		# 	# parameters: [
		# 	# 	# url: 'https://s3-us-west-1.amazonaws.com/projectgutenbergtest/books/alice_in_wonderland.txt'
		# 	# 	# features: {:concepts => {:limit => 8}, :emotions => true}
		# 	# ]
		# ).body

		# Book.nlu_analysis(@book.url)
	end

	def new
	end

	def create

		# binding.pry
		
		# validations - checks if there is a file or url present
		if params[:form_identifier] == "url"
			puts "Conditional URL identifier"
			if params[:url] == ""
				puts "URL isnt here"
				flash[:danger] = "Please choose a url or file"
				redirect_to "/books/new"
				return
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
		elsif (params[:url] && params[:title] == "" && params[:url].starts_with?("https://www.reddit.com") || params[:url].starts_with?("www.reddit.com") && params[:url].include?("/comments/"))
			webpage = Nokogiri::HTML(
				open(
					params[:url],
					"User-Agent" => "OpenBooks"
				) 
			)
			params[:title] = webpage.at('title').inner_text
		elsif params[:url] && params[:title] == ""
			webpage = Nokogiri::HTML(open params[:url])
			params[:title] = webpage.at('title').inner_text
		end



		params[:card_title] = params[:title].truncate(27)



		if params[:file] # this means that a file was uploaded
			book_url = Book.create_s3_object(params) # takes in params, stores text as s3 obj, returns a url for the obj

			@book = Book.new(title: params[:title], card_title: params[:card_title], url: book_url)
			@book.save # save the book so it has an id when we pass it to the wordcount json builder

			book_json_url = Book.create_book_wordcount(@book)

			@book.update(book_cloud_url: book_json_url)

		elsif params[:url] # this means that a webpage url was given
			title = params[:title]
			url = params[:url]

			fixed_url = Book.fix_url(url)

			@book = Book.new(title: title, card_title: params[:card_title], url: fixed_url)
			@book.save

			book_json_url = Book.create_webpage_wordcount(@book)

			@book.update(book_cloud_url: book_json_url)
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
