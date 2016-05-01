require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'password_here'

BLACKJACK = 21
DEALER_MIN_HIT = 17
INITIAL_POT = 1000

before do
  @hide_first_card = true
end

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
      total -= 10 if total > BLACKJACK
    end
    total
  end

  def display_card_image(card)
    suit = case card[1]
           when "H" then "hearts"
           when "D" then "diamonds"
           when "C" then "clubs"
           when "S" then "spades"
           end

    value = card[0]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[0]
              when "J" then "jack"
              when "Q" then "queen"
              when "K" then "king"
              when "A" then "ace"
              end
    end
    "<img src='images/cards/#{suit}_#{value}.jpg' class='card' />"
  end

  def win(msg)
    @success = msg
    @play_again = true
    session[:money_left] += session[:bet]
    @hide_first_card = false
  end

  def lose(msg)
    @error = msg
    @play_again = true
    session[:money_left] -= session[:bet]
    @hide_first_card = false
  end
end

get '/' do
  if session[:player_name]
    redirect '/betting'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:money_left] = INITIAL_POT
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Please enter your name."
    halt erb :new_player
  end
  session[:player_name] = params[:player_name]
  redirect '/betting'
end

get '/betting' do
  session[:bet] = nil
  erb :betting
end

post '/betting' do
  if params[:bet].nil? || params[:bet].to_i == 0
    @error = "Please bet at least $1."
    halt erb :betting
  elsif params[:bet].to_i > session[:money_left]
    @error = "You can't bet more than you have!"
    halt erb :betting
  else
    session[:bet] = params[:bet].to_i
    redirect '/game'    
  end
end

get '/game' do
  values = %w(2 3 4 5 6 7 8 9 10 J K Q A)
  suits = %w(C H S D)
  session[:deck] = values.product(suits).shuffle!
  session[:player_cards] = []
  session[:dealer_cards] = []
    2.times do
      session[:player_cards] << session[:deck].pop
      session[:dealer_cards] << session[:deck].pop
    end
  if calculate_total(session[:player_cards]) == BLACKJACK
    win("Whoa that's lucky! You hit blackjack, congratulations! You win $#{session[:bet]}.")
  elsif calculate_total(session[:dealer_cards]) == BLACKJACK
    lose("Whoa that's lucky! Dealer hit blackjack. You lose $#{session[:bet]}. Maybe next time.")
  end
  erb :game
end

post '/hit' do
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) > BLACKJACK
    lose("Oh no! You busted! You lose $#{session[:bet]}. Maybe next time.")
  elsif calculate_total(session[:player_cards]) == BLACKJACK
    win("Congratulations! You hit blackjack. You win $#{session[:bet]}.")
  end
  erb :game
end

post '/stay' do
  win("You chose to stay with a total of #{calculate_total(session[:player_cards])}.")
  redirect '/dealer'
end

get '/dealer' do
  @hide_first_card = false
  if calculate_total(session[:dealer_cards]) == BLACKJACK
    lose("Oh no! Dealer hit blackjack. You lose $#{session[:bet]}. Maybe next time.")
  elsif calculate_total(session[:dealer_cards]) > BLACKJACK
    win("Congrats! Dealer busts, you win $#{session[:bet]}!")
  elsif calculate_total(session[:dealer_cards]) < DEALER_MIN_HIT
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
  @hide_first_card = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total > dealer_total
    win("Congratulations! You win $#{session[:bet]}!")
  elsif player_total < dealer_total
    lose("Oh no! Dealer wins. You lose $#{session[:bet]}. Maybe next time.")
  else
    lose("It's a tie.")
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end
