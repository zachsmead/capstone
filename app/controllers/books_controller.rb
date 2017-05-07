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
	end

	def new
	end

	def create
		# Step 1. Make the book in S3
		# Make an object in your bucket for your upload

		if params[:file]
			title = params[:file].original_filename
			title_without_extensions = File.basename(title, '.txt')

			uploaded_book = S3_BUCKET.objects[("books/" + title)]

			# Upload the file
			uploaded_book.write(
				file: params[:file], # we get this param from the file_field_tag in books/new.html.erb
				acl: :public_read
			)

			# @book = Book.new(title: uploaded_book.key, url: uploaded_book.public_url)

			# Step 2. Create a row in our own database to represent the book
			@book = Book.new(title: title, url: uploaded_book.public_url)

			if @book.save
				redirect_to books_path, success: 'File successfully uploaded'
			else
				flash.now[:notice] = 'There was an error'
				render :new
			end

			# Step 3. Make the book_cloud in S3 (just a hash of word frequencies)
			# Start by grabbing the book plaintext
			@book_text = Unirest.get(
				@book.url,
				headers: {
					"Accept" => "text/plain"
				}
			).body

			# Run the breakdown method which converts the book to a word-count
			@book_frequencies = Book.breakdown_test(@book_text, 'book')

			# Make a javascript file in the bucket
			book_javascript = S3_BUCKET.objects.create(
				"book_clouds/" + title_without_extensions + '_' + @book.id.to_s + '.js', @book_frequencies
			)
			book_javascript.acl = :public_read

			# Step 4. Update the book object with the book_cloud_url
			@book.update(book_cloud_url: book_javascript.public_url)

		elsif params[:url] && params[:title]
			title = params[:title]
			
			if params[:url].include?('https://')
				url = params[:url]
			else
				url = 'https://' + params[:url]
			end

			# Step 1. Declare object 'page' and 'page_text' for the text of params[:url]
			page = Nokogiri::HTML(open url)
			page_text = page.at('body').inner_text
			s3_title = page.at('title').inner_text[0..45].parameterize('_')

			# Step 2. try to make a new book in database
			@book = Book.new(title: title, url: url)

			if @book.save
				redirect_to books_path, success: 'File successfully uploaded'
			else
				flash.now[:notice] = 'There was an error'
				render :new
			end

			# Step 3. make the page's wordcloud
			# Run the breakdown method which converts the page to a word-count
			# call the method with big = false, so we count every word on the page.
			@book_frequencies = Book.breakdown_test(page_text, 'page')

			# Make a javascript file in the bucket, give it a unique name from the book object id in our db
			book_javascript = S3_BUCKET.objects.create(
				"book_clouds/" + s3_title + '_' + @book.id.to_s + '.js', @book_frequencies
			)
			book_javascript.acl = :public_read

			# Step 4. Update the book object with the book_cloud_url
			@book.update(book_cloud_url: book_javascript.public_url)

		# end if statement
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
