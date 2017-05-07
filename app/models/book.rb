class Book < ApplicationRecord

	# book likes
	has_many :users, through: :book_likes
	has_many :book_likes

	# book genres
	has_many :genres, through: :book_genres
	has_many :book_genres

	def self.breakdown_test(text)
		
		book_array = text.downcase.gsub(/[^a-z0-9\s]/i, '').split(" ")
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
			'lets'#7524
			'itll',#7902
			'h',
			'b',
			'4',
			'sh',
			'sat' #past 10000
		]

		book_hash = {}
		hashified_words = []
		javascript_hash_string = "var words = ["

		book_array.each do |word|
			if boring_words.include? word
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
			unless word_freq_pair[1] <= 1
				hashified_words << { text: word_freq_pair[0], size: word_freq_pair[1]}
			end
		end

		javascript_hash = "var words = #{hashified_words.to_json}"

		return javascript_hash

	end

end
