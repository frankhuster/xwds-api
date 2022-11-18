# frozen_string_literal: true

require 'securerandom'

# TODO: players shouldn't open multiple games
# Game API
module Game
  def player_already_playing?(uuid)
    doc_ref = firestore.doc("players/#{uuid}")
    snapshot = doc_ref.get
    return [404, headers, ['No such player']] unless snapshot.exists?

    snapshot.data[:game].to_s.length.positive?
  end

  def save_game_and_update_player(player_id, player_name, board_size, tray_size, number_of_players)
    id = SecureRandom.uuid
    firestore.transaction do |tx|
      tx.set("games/#{id}",
             { board_size:, tray_size:, players: [{ name: player_name, order: 0 }], number_of_players:,
               status: 'open' })
      tx.update("players/#{player_id}", { game: id })
    end
    [201, [{ id: }.to_json]]
  end

  def new_game(payload)
    return [409, ['Player is already playing']] if player_already_playing?(payload['player_id'])

    save_game_and_update_player(payload['player_id'],
                                payload['player_name'],
                                payload['board_size'] || 11,
                                payload['tray_size'] || 7,
                                payload['number_of_players'] || 2)
  end

  def fetch_open_games
    ref = firestore.col('games')
    query = ref.where('status', '=', 'open')
    games = []
    query.get do |game|
      g = { id: game.document_id, players: game.data[:players] }.to_s
      games << g
    end

    [200, games]
  end

  def retrieve_game(player_id)
    snapshot = firestore.doc("players/#{player_id}").get
    return [404, 'No such player'] unless snapshot.exists?

    game_id = snapshot.data[:game]
    return [404, 'Player has no game, lol'] if game_id.empty?

    snapshot = firestore.doc("games/#{game_id}").get
    return [404, 'Missing game'] unless snapshot.exists?

    [200, snapshot.data.to_json]
  end
end
