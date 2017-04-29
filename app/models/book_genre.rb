class BookGenre < ApplicationRecord
	belongs_to :book, :genre
end
