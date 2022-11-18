# frozen_string_literal: true

require 'functions_framework'
require 'sinatra/base'
require './firestore'
require './player'
require './game'

# Sinatra API
class App < Sinatra::Base
  include Player
  include Game

  put '/player' do
    register_player
  end

  get(%r{/player/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})}) do |uuid|
    retrieve_player(uuid)
  end

  put '/game' do
    payload = begin
      JSON.parse(request.body.read)
    rescue StandardError => e
      return [400, "Error parsing JSON request body: #{e}"]
    end
    return [400, 'Missing player_id payload key'] unless payload.is_a?(Hash) && payload.key?('player_id')

    new_game(payload)
  end

  get '/open-games' do
    fetch_open_games
  end

  get(%r{/game/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})}) do |uuid|
    retrieve_game(uuid)
  end
end

FunctionsFramework.http 'xwds_api' do |request|
  App.call request.env
end
