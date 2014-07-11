class StaticPagesController < ApplicationController

  def home
    if signed_in?
      @micropost  = current_user.microposts.build
      #@feed_items = current_user.feed.paginate(page: params[:page])
      #binding.pry
      @feed_items = current_user.feed(search_word: params[:search_word]).paginate(page: params[:page])
    end
  end

  def help
  end

  def about
  end

  def contact
  end
end
