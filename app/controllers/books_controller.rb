class BooksController < ApplicationController

	def index
		Book.breakdown_test
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

		@book_text = Unirest.get(
			@book.url,
			headers: {
				"Accept" => "text/plain"
			}
		).body

		# puts @book_text

		@book_frequencies = Book.breakdown_test(@book_text)


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

		uploaded_book = S3_BUCKET.objects[("books/" + title)]

		# Upload the file
		uploaded_book.write(
			file: params[:file], # we get this param from the file_field_tag in books/new.html.erb
			acl: :public_read
		)

		# Create an object for the upload
		# @book = Book.new(title: obj.key, url: obj.public_url)
		@book = Book.new(title: title, url: obj.public_url)

		if @book.save
			redirect_to books_path, success: 'File successfully uploaded'
		else
			flash.now[:notice] = 'There was an error'
			render :new
		end

		# Step 2. Make the book_cloud in S3 (just a hash of word frequencies)

		# book_cloud = S3_BUCKET.objects[("book_clouds/" + title)]

		# book_cloud.write(
		# 	file: 
		# )

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
