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

		puts "*" * 100
		puts params[:file]
		puts "*" * 100
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
		@book_frequencies = Book.breakdown_test(@book_text)

		# Make a javascript file in the bucket
		book_javascript = S3_BUCKET.objects.create("book_clouds/" + title_without_extensions + '.js', @book_frequencies)
		book_javascript.acl = :public_read

		# Step 4. Update the book object with the book_cloud_url
		@book.update(book_cloud_url: book_javascript.public_url)

		
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
