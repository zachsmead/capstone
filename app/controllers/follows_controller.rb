class FollowsController < ApplicationController

	def index
		@current_user_id = current_user.id
		@users = User.all
	end

	def create
		followee_id = params[:followee_id]

		p "*" * 100
		p followee_id
		p "*" * 100
 
		unless (followee_id == current_user.id || Follow.find_by(followee_id: followee_id, follower_id: current_user.id))
			@follow = Follow.create(followee_id: followee_id, follower_id: current_user.id)
		end
	end

end
