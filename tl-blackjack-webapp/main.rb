require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'password_here'

helpers do
  def calculate_total(cards)
    array_of_faces = cards.map { |pair| pair[0] }
    total = 0

    array_of_faces.each do |face|
      if face == "A"
        total += 11
      elsif ["J", "Q", "K"].include?(face)
        total += 10
      else
        total += face.to_i
      end
    end

    #correct for aces
    array_of_faces.count { |face| face == "A" }.times do
      total -= 10 if total > 21
    end
    total
  end

  def display_card_image(card)
    suit = case card[1]
      when "H" then
        "hearts"
      when "D"
        "diamonds"
      when "C"
        "clubs"
      when "S"
        "spades"
      end

    value = card[0]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[0]
      when "J"
        "jack"
      when "Q"
        "queen"
      when "K"
        "king"
      when "A"
        "ace"
      end
    end
    "<img src='images/cards/#{suit}_#{value}.jpg' class='card'>"
  end
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Please enter your name."
    halt erb :new_player
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  values = %w(2 3 4 5 6 7 8 9 10 J K Q A)
  suits = %w(C H S D)
  session[:deck] = values.product(suits).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) == 21
    @success = "Whoa that's lucky! You hit blackjack, congratulations!"
  elsif calculate_total(session[:dealer_cards]) == 21
    @error = "Whoa that's lucky! Dealer hit blackjack. Maybe next time."
  end
  erb :game
end

post '/hit' do
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) > 21
    @error = "Oh no! You busted! Maybe next time."
  elsif calculate_total(session[:player_cards]) == 21
    @success = "Congratulations! You hit blackjack."
  end
  erb :game
end

post '/stay' do
  @success = "You chose to stay with a total of #{calculate_total(session[:player_cards])}."
  redirect '/dealer'
end

get '/dealer' do
  if calculate_total(session[:dealer_cards]) == 21
    @error = "Oh no! Dealer hit blackjack. Maybe next time."
  elsif calculate_total(session[:dealer_cards]) > 21
    @success = "Congrats! Dealer busts, you win!"
  elsif calculate_total(session[:dealer_cards]) < 17
    @show_dealer_button = true
  else 
    redirect '/compare'
  end
  erb :game
end

post '/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/dealer'
end

get '/compare' do
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total > dealer_total
    @success = "Congratulations! You win!"
  elsif player_total < dealer_total
    @error = "Oh no! Dealer wins. Maybe next time."
  else
    @error = "It's a tie."
  end

  erb :game
end
