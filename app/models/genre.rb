class Genre < ApplicationRecord

	# book genres
	has_many :books, through: :book_genres
	has_many :book_genres


end
