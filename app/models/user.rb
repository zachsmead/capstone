class User < ApplicationRecord

  # follower relationships
  has_many :followers, through: :follower_follows, source: :follower
  has_many :follower_follows, foreign_key: :followee_id, class_name: "Follow"

  has_many :followees, through: :followee_follows, source: :followee
  has_many :followee_follows, foreign_key: :follower_id, class_name: "Follow"

  # book likes
  has_many :books, through: :book_likes
  has_many :book_likes



  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook]

  def self.from_omniauth(auth)
    @user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      # first_or_create checks if a user already exists in the database, with provider and uid columns
      # that match those given by the provider.
      # if there is a match, it will return the first match.
      # if no match, it will create a new user where

      user.email = auth.info.email

      user.password = Devise.friendly_token[0,20]

      # user.name = auth.info.name   # assuming the user model has a name
      # user.image = auth.info.image # assuming the user model has an image
      # If you are using confirmable and the provider(s) you use validate emails, 
      # uncomment the line below to skip the confirmation emails.
      # user.skip_confirmation!
    end

  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

end
