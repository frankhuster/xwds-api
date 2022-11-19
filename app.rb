# frozen_string_literal: true

require 'functions_framework'
require 'sinatra/base'
require 'sinatra/cross_origin'
require './firestore'
require './player'
require './game'

# Sinatra API
class App < Sinatra::Base
  include Player
  include Game

  register Sinatra::CrossOrigin
  set :allow_origin, :any
  set :allow_methods, %i[get put]
  set :expose_headers, ['Content-Type']

  configure do
    enable :cross_origin
  end

  options '*' do
    response.headers['Allow'] = 'GET,PUT,OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Access-Control-Allow-Origin'
    200
  end

  put '/player' do
    register_player
  end

  get(%r{/player/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})}) do |uuid|
    retrieve_player(uuid)
  end

  #
  # Create new game
  #
  put '/game' do
    payload = begin
      JSON.parse(request.body.read)
    rescue StandardError => e
      return [400, "Error parsing JSON request body: #{e}"]
    end

    return [400, 'Payload must be a hash'] unless payload.is_a?(Hash)
    return [400, 'Missing player_id key'] unless payload.key?('player_id')
    return [400, 'Missing player_nme key'] unless payload.key?('player_name')

    new_game(payload)
  end

  #
  # Join an open game
  #
  put(%r{/game/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})}) do
    payload = begin
      JSON.parse(request.body.read)
    rescue StandardError => e
      return [400, "Error parsing JSON request body: #{e}"]
    end

    return [400, 'Payload must be a hash'] unless payload.is_a?(Hash)
    return [400, 'Missing player_id key'] unless payload.key?('player_id')
    return [400, 'Missing player_nme key'] unless payload.key?('player_name')

    join_game(payload)
  end

  #
  # Fetch open games
  #
  get '/open-games' do
    fetch_open_games
  end

  #
  # Fetch game data
  #
  get(%r{/game/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})}) do |uuid|
    fetch_game(uuid)
  end
end

FunctionsFramework.http 'xwds_api' do |request|
  App.call request.env
end
