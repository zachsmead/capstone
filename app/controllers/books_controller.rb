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
	end

	def new
	end

	def create

		# Make an object in your bucket for your upload
		# filename = File.basename(params[:file])

		file = File.read(params[:file])

		puts file

		obj = S3_BUCKET.objects[params[:file].original_filename]

		puts "*" * 100
		puts obj.inspect
		puts "*" * 100

		# Upload the file
		obj.write(
			file: params[:file], # we get this param from the form_tag in books/new.html.erb
			acl: :public_read
		)

		# Create an object for the upload
		@book = Book.new(title: obj.key, url: obj.public_url)

		if @book.save
			redirect_to books_path, success: 'File successfully uploaded'
		else
			flash.now[:notice] = 'There was an error'
			render :new
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
