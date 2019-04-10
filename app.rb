# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/activerecord'
require './fakeDataGenerator'
require './src/availability.rb'
require 'bcrypt'
require 'json'
# current_dir = Dir.pwd
current_dir = Dir.pwd

Dir["#{current_dir}/models/*.rb"].each { |file| require file }

class Makersbnb < Sinatra::Base
  include BCrypt

  set :root, File.dirname(__FILE__)
  set :public_folder, File.dirname(__FILE__)

  enable :sessions

  get '/' do
    redirect '/index'
  end

  get '/index' do
    # User gets passed to index page
    # @user is processed in the layout.erb
    # layout erb, via the yeild method, brings in the index page, that's why @user works in the index page
    @user = User.find(session[:id]) if session[:id]
    erb :index
  end

  # USER CREATION
  # get '/users/new' do
  #   erb :signup
  # end

  # SIGN UP ROUTE
  post '/users/new' do
    encrypted_password = BCrypt::Password.create(params[:password])
    user = User.create(
      first_name: params[:firstName],
      last_name: params[:lastName],
      email: params[:email],
      password_digest: encrypted_password
    )
    session[:id] = user[:id]
    redirect '/index'
  end

  get '/users/show/:id' do
    # p User.find(params[:id])
  end

  # LISTINGS
  # This sends JSON object to frontend
  get '/api/listings' do
    content_type :json
    listings = Listing.all.reverse_order.as_json

    listings.map { |listing| listing['available_start_date'] = listing['available_start_date'].strftime('%d/%m/%Y') }
    listings.map { |listing| listing['available_end_date'] = listing['available_end_date'].strftime('%d/%m/%Y') }

    listings.to_json
  end

  get '/listings/new' do
    # Not needed as @user, if there is a session[:id], it is assigned in the layout
    # @user = User.find(session[:id]) if session[:id]
    erb :'/listings/new'
  end

  # FILTERING ROUTES START
  # Click apply in daterange picker
  # 1. Daterange function (filterInterface.js) sends dates to /api/listings/dates

  post '/api/listings/dates' do
    session[:start] = params[:start]
    session[:end] = params[:end]
  end

  # 2. Daterange function (filterInterface.js) routes to this page listings/show
  get '/listings/show' do
    erb :'listings/show'
  end

  # 3. listings/show creates the webpage and sends a get reuquest to the end point below
  # CALLING THIS API FROM listings/show page
  get '/api/listings/get/filtered' do
    listings = CheckAvailability.check_dates(session[:start], session[:end])

    listings.map { |listing| listing['available_start_date'] = listing['available_start_date'].strftime('%d/%m/%Y') }
    listings.map { |listing| listing['available_end_date'] = listing['available_end_date'].strftime('%d/%m/%Y') }

    listings.to_json
  end

  # FILTERING ROUTES END

  post '/listings/new' do
    listing = Listing.create(
      name: params[:name],
      location: params[:location],
      city: params[:city],
      price_per_night: params[:price],
      user_id: session[:id],
      available_start_date: params[:startDate],
      available_end_date: params[:endDate],
      description: params[:description]
    )
    redirect '/index'
  end

  # SESSION FOR USER ID
  # get '/sessions/new/login' do
  #   erb :login
  # end

  # LOGIN ROUTE

  get '/listings/:listing_id/new' do
    @listing_id = params[:listing_id]
    @listing = Listing.find(@listing_id)
    @start_date = [@listing[:available_start_date], Date.today].max.strftime('%Y-%m-%d')
    @end_date = @listing[:available_end_date].strftime('%Y-%m-%d')
    @user_id = session[:id]
    @user = User.find(@user_id) if @user_id
    erb :"spaces/spaces"
  end

  post '/listings/:listing_id/new' do
    p params
    @listing_id = params[:listing_id]
    @start_date = params[:start_date]
    @user_id = session[:id]
    @user = User.find(@user_id) if @user_id
    Request.create(
      start_date: @start_date,
      listing_id: @listing_id,
      user_id: @user_id
    )
    redirect '/index'
  end

  post '/sessions' do
    user = User.find_by(email: params[:email]) # email must be unique

    if BCrypt::Password.new(user[:password_digest]) == params[:password]
      session[:id] = user[:id]

      redirect '/index'
    else
      redirect '/index'
    end
    # return unless BCrypt::Password.new(user[:password_digest]) == params[:password]
  end

  post '/sessions/destroy' do
    session.clear
    redirect '/index'
  end

  # Alex
  get '/users/:user_id/requests' do
    # shows all requests for the user
    @user_id = params[:user_id]
    @user = User.find(@user_id) if @user_id
    @requests_submitted = Request.where(user_id: params[:user_id])
    @hostslistings = Listing.where(user_id: @user_id)
    @requests_received = []

    @hostslistings.each do |listing|
      @requests_received_per_listing = Request.where(listing_id: listing.id) if Request.where(listing_id: listing.id) != nil
      @requests_received_per_listing.each do |x|
        @requests_received << x
      end
    end
    erb :'requests/index'
  end

  run! if app_file == $PROGRAM_NAME
end
