# frozen_string_literal: true

require 'securerandom'

# Firestore
#
# Games collection path
#
# /games
#
#
# sample open game waiting for one extra player
#
# {
#   "status" : "open",
#   "board_size": 7,
#   "tray_size": 5,
#   "number_of_players": 2,
#   "players": [ "karin" ]
# }
#
# TODO: players shouldn't open multiple games
#
module Game
  def player_already_playing?(player_id)
    doc_ref = firestore.doc("players/#{player_id}")
    snapshot = doc_ref.get
    return [404, headers, ['No such player']] unless snapshot.exists?

    snapshot.data[:game].to_s.length.positive?
  end

  def create_game(game_data, player_id)
    game_id = SecureRandom.uuid
    firestore.transaction do |tx|
      tx.set("games/#{game_id}", game_data)
      tx.update("players/#{player_id}", { game: game_id })
    end
    [201, [{ game_id: }.to_json]]
  end

  def game_data(payload)
    {
      status: 'open',
      board_size: payload['board_size'] || 11,
      tray_size: payload['tray_size'] || 7,
      players: [payload['player_name']],
      number_of_players: payload['number_of_players'] || 2
    }
  end

  def new_game(payload)
    return [409, ['Player is already playing']] if player_already_playing?(payload['player_id'])

    create_game(game_data(payload))
  end

  def add_player_to_game(game_id, player_name)
    firestore.transaction do |tx|
      snapshot = firestore.doc("games/#{game_id}").get
      return [404, 'Missing game'] unless snapshot.exists?

      game_data = snapshot.data
      game_data['players'] << player_name
      tx.set("games/#{game_id}", game_data)

      tx.update("players/#{player_id}", { game: game_id })
    end
    200
  end

  def join_game(payload)
    return [409, ['Player is already playing']] if player_already_playing?(payload['player_id'])

    add_player_to_game(payload['player_id'], payload['player_name'])
  end

  def fetch_open_games
    ref = firestore.col('games')
    query = ref.where('status', '=', 'open')
    games = []
    query.get do |game|
      g = { id: game.document_id, players: game.data[:players] }
      games << g
    end

    [200, [games.to_json]]
  end

  def fetch_game(player_id)
    snapshot = firestore.doc("players/#{player_id}").get
    return [404, 'No such player'] unless snapshot.exists?

    game_id = snapshot.data[:game]
    return [404, 'Player has no game, lol'] if game_id.empty?

    snapshot = firestore.doc("games/#{game_id}").get
    return [404, 'Missing game'] unless snapshot.exists?

    [200, snapshot.data.to_json]
  end
end
