class Book < ApplicationRecord

	# book likes
	has_many :users, through: :book_likes
	has_many :book_likes

	# book genres
	has_many :genres, through: :book_genres
	has_many :book_genres

	def self.s3_text_upload(params)
		# We want this method to:
		# 1. take the params hash,
		# 2. Make a s3 storage object named/located by the params,
		# 3. return a url that the controller can save with the book.

		book_attributes_hash = {}
		# book_attributes_hash[:title] = params[:file].original_filename # 1st important thing to return
		title_without_extensions = File.basename(params[:title], '.txt').parameterize('_')
		random_number = rand.to_s[2..6]

		uploaded_book = S3_BUCKET.objects[(
			"books/" + title_without_extensions + '_' + random_number + '.txt'
		)]

		# Upload the file
		uploaded_book.write(
			file: params[:file], # we get this param from the file_field_tag in views/books/new.html.erb
			acl: :public_read
		)

		return uploaded_book.public_url # 2nd important thing to return
	end


	def self.s3_text_upload_json(book) # make a wordcount json in s3 for uploaded text input
		@book_text = Unirest.get(
			book.url,
			headers: {
				"Accept" => "text/plain"
			}
		).body

		@book_frequencies = Book.breakdown(@book_text, 'book')
		title_without_extensions = File.basename(book.title, '.txt')
		p title_without_extensions

		book_json = S3_BUCKET.objects.create(
			"book_clouds/" + title_without_extensions + '_' + book.id.to_s + '.js', @book_frequencies
		)
		book_json.acl = :public_read

		return book_json.public_url # return the url of this wordcloud so we can update book in the controller
	end


	def self.fix_url(url)
		if url.include?('https://') # add 'https://' so the computer can read it properly
			fixed_url = url
		else
			fixed_url = 'https://' + url
		end

		return fixed_url
	end


	def self.s3_web_content_json(page) 		# make a wordcount json in s3 for web content input
																				# => NOTE: also saves a s3 text file for scraped content

		url = page.url # the url we're going to scrape from
		reddit_username = page.reddit_username
		twitter_username = page.twitter_username
		s3_title = page.title[0..45].parameterize('_')
		attributes = {}

		if url
			if url.starts_with?("https://www.reddit.com") || url.starts_with?("www.reddit.com") && url.include?("/comments/")
				webpage_text = Reddit.start_comment_recursion(url)
				type = 'page'
				# s3_title = page.title.gsub(/[^a-z\s]/i, '').parameterize('_')
			end
		elsif twitter_username
			# perform the text grab on all the username's tweets
			twitter_client = TwitterGrab.new
			tweets = twitter_client.get_all_tweets(twitter_username) # get all the tweets from the user
			webpage_text = twitter_client.tweets_into_string(tweets)

			if webpage_text.length > 20000
				type = 'book'
			else
				type = 'page'
			end
		elsif reddit_username
			# grab all the user's comments
			webpage_text = Reddit.grab_user_comments(reddit_username, '')
			type = 'page'
		else
			webpage = Nokogiri::HTML(open url)
			webpage_text = webpage.at('body').inner_text
			type = 'page'
			# s3_title = webpage.at('title').inner_text[0..45].parameterize('_') # set a title based on the webpage title
		end
		
		page_frequencies = Book.breakdown(webpage_text, type)

		# Make a javascript file in the bucket, give it a unique name using book object's id
		frequency_count_json = S3_BUCKET.objects.create(
			"book_clouds/" + s3_title + '_' + page.id.to_s + '.js', page_frequencies
		)
		frequency_count_json.acl = :public_read

		attributes[:book_cloud_url] = frequency_count_json.public_url # return the url of this wordcloud so we can update book in the controller
		attributes[:scraped_content_url] = Book.s3_store_scraped_content(s3_title, page, webpage_text) 
		# ^ run the method s3_store_scraped_content to store the scraped content, which also returns the public url of that stored object

		return attributes
	end


	def self.s3_store_scraped_content(s3_title, page, content_string)
		stored_string = S3_BUCKET.objects.create(
			"scraped_content/" + s3_title + '_' + page.id.to_s + '.txt', content_string
		)
		stored_string.acl = :public_read
		return stored_string.public_url 
	end


	def self.breakdown(text, type)
		
		book_array = text.downcase.gsub(/[^a-z\s]/i, '').split(" ")
		# puts book_array

		boring_words = [
			'the',
			'of',
			'and',
			'to',
			'in',
			'i',
			'that',
			'was',
			'his',
			'he',
			'it',
			'with',
			'is',
			'for',
			'as',
			'had',
			'you',
			'not',
			'be',
			'her',
			'on',
			'at',
			'by',
			'which',
			'have',
			'or',
			'from',
			'this',
			'him',
			'but',
			'all',
			'she',
			'they',
			'were',
			'my',
			'are',
			'me',
			'one',
			'their',
			'so',
			'an',
			'said',
			'them',
			'we',
			'who',
			'would',
			'been',
			'will',
			'no',
			'when',
			'there',
			'if',
			'more',
			'out',
			'up',
			'into',
			'do',
			'any',
			'your',
			'what',
			'has',
			'man',
			'could',
			'other',
			'than',
			'our',
			'some',
			'very',
			'time',
			'upon',
			'about',
			'may',
			'its',
			'only',
			'now',
			'like',
			'little',
			'then',
			'can',
			'should',
			'made',
			'did',
			'us',
			'such',
			'a',
			'great',
			'before',
			'must',
			'two',
			'these',
			'see',
			'know',
			'over',
			'much',
			'down',
			'after',
			'first',
			'mr',
			'good',
			'men',
			'own',
			'never',
			'most',
			'old',
			'shall',
			'day',
			'where',
			'those',
			'came',
			'come',
			'himself',
			'way',
			'work',
			'life',
			'without',
			'go',
			'make',
			'well',
			'through',
			'being',
			'long',
			'say',
			'might',
			'how',
			'am',
			'too',
			'even',
			'def',
			'again',
			'many',
			'back',
			'here',
			'think',
			'every',
			'people',
			'went',
			'same',
			'last',
			'thought',
			'away',
			'under',
			'take',
			'found',
			'hand',
			'eyes',
			'still',
			'place',
			'while',
			'just',
			'also',
			'young',
			'yet',
			'though',
			'against',
			'things',
			'get',
			'ever',
			'give',
			'god',
			'years',
			'off',
			'face',
			'nothing',
			'right',
			'once',
			'another',
			'left',
			'part',
			'saw',
			'house',
			'world',
			'head',
			'three',
			'took',
			'new',
			'always',
			'mrs',
			'put',
			'night',
			'each',
			'between',
			'tell',
			'few',
			'because',
			'thing',
			'whom',
			'far',
			'seemed',
			'looked',
			'called',
			'whole',
			'de',
			'set',
			'both',
			'got',
			'find',
			'done',
			'heard',
			'look',
			'name',
			'days',
			'told',
			'let',
			'asked',
			'going',
			'seen',
			'better',
			'p',
			'having',
			'home',
			'knew',
			'side',
			'something',
			'moment',
			'among',
			'course',
			'hands',
			'enough',
			'words',
			'soon',
			'full',
			'end',
			'gave',
			'room',
			'almost',
			'small',
			'thou',
			'cannot',
			'water',
			'want',
			'however',
			'light',
			'quite',
			'brought',
			'nor',
			'word',
			'whose',
			'given',
			'door',
			'best',
			'turned',
			'taken',
			'does',
			'use',
			'morning',
			'myself',
			'project',
			'gutenberg',
			'gutenbergtm',
			'felt',
			'until',
			'since',
			'themselves',
			'used',
			'rather',
			'began', #264
			'present',
			'voice',
			'others',
			'works',
			'less',
			'money',
			'next',
			'poor',
			'stood',
			'form',
			'within',
			'together',
			'till',
			'thy',
			'large',
			'matter',
			'kind',
			'often',
			'certain',
			'herself',
			'year',
			'friend',
			'half',
			'order',
			'round',
			'true',
			'anything',
			'keep',
			'sent',
			'means',
			'belief',
			'passed',
			'feet',
			'near',
			'public',
			'state',
			'son',
			'hundred',
			'thus',
			'hope',
			'alone',
			'above',
			'case',
			'dear',
			'thee',
			'says',
			'person',
			'high',
			'read',
			'already',
			'received',
			'fact',
			'gone',
			'known',
			'hear',
			'times',
			'least',
			'perhaps',
			'sure',
			'indeed',
			'english',
			'open',
			'body',
			'itself',
			'along',
			'land',
			'return',
			'leave',
			'air',
			'answered',
			'either',
			'law',
			'help',
			'lay',
			'point',
			'child',
			'letter',
			'four',
			'wish',
			'fire',
			'cried',
			'2',
			'women',
			'speak',
			'number',
			'therefore',
			'hour',
			'held',
			'free',
			'during',
			'several',
			'whether',
			'er',
			'manner',
			'second',
			'reason',
			'replied', #371
			'united',
			'call',
			'general',
			'why',
			'behind',
			'became',
			'become',
			'ill',#387
			'im',
			'id',
			'your',
			'yours',
			'coming',
			'really',
			'rest',
			'mean',
			'different',
			'making',#402
			'terms',
			'hold', #443
			'cant', #462
			'spoke', #471
			'saying', #478
			'ive',#515
			'didnt',#542
			'laid', #557
			'copyright',#560
			'doing', #561
			'opened', #566
			'makes', #579
			'ago',#614
			'yourself', #607
			'wont', #673
			'including', #686
			'please', #696
			'stopped', #737
			'begin', #858
			'ways', #875
			'speaking', #829
			'trademark', #924
			'reply', #968
			'id', #969
			'stop', #1001
			'hes', #1065
			'couldnt',#1099
			'isnt', #1113
			'dont', #unknown
			'em',#1147
			'yes',#1157
			'theres',#1238
			'refund',
			'distribution',
			'yours',
			'anyone', #1291
			'youll',#1445
			'wasnt', #1618
			'doesnt', #1687
			'havent', #1845
			'everybody', #1872
			'youve',#1904
			'youre', #unknown
			'hers',#2168
			'chapter', #2328
			'whats', #2435
			'links',#2467
			'online',
			'web',
			'tis',#2285
			'inches', #2379
			'youd',#2413
			'hadnt', #2526
			'ebook',
			'ebooks',
			'theyre', #3151
			'someone', #3157
			'theirs',#3982
			'hasnt',#4590
			'shed', #5749
			'theyd', #6254
			'shant', #6514
			'lets',#7524
			'itll',#7902
			'h',
			'b',
			'4',
			'sh',
			'sat' #past 10000
		]

		book_hash = {}
		hashified_words = []
		# javascript_hash_string = "var words = ["

		book_array.each do |word|
			if boring_words.include? word
				next
			elsif word.length > 15
				next
			elsif book_hash[word]
				book_hash[word] += 1
			else
				book_hash[word] = 1
			end
		end

		book_hash = book_hash.sort_by { |word, freq| -freq }

		# string way

		# book_hash.each do |word_freq_pair|
		# 	javascript_hash_string += "{ text: '#{word_freq_pair[0]}', size: #{word_freq_pair[1]} },"
		# end

		# javascript_hash_string[javascript_hash_string.length - 1] = ""
		# javascript_hash_string += "]"
		# return javascript_hash_string

		# hash way

		book_hash.each do |word_freq_pair|
			if type == 'book'
				unless word_freq_pair[1] <= 1
					hashified_words << { text: word_freq_pair[0], size: word_freq_pair[1]}
				end
			elsif type == 'page'
					hashified_words << { text: word_freq_pair[0], size: word_freq_pair[1]}
			end
		end

		javascript_hash = "var words = #{hashified_words.to_json}"

		return javascript_hash

	end # end method self.breakdown



end
