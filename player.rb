# frozen_string_literal: true

require 'securerandom'

# Player API
module Player
  def player_exists?(name)
    players_ref = firestore.col('players')
    query = players_ref.where 'name', '=', name
    query.get do |_player|
      return true
    end
    false
  end

  def add_player(name)
    id = SecureRandom.uuid
    player_ref = firestore.doc("players/#{id}")
    player_ref.set({ name:, game: '' })
    [201, [{ id: }.to_json]]
  end

  def register_player
    payload = begin
      JSON.parse(request.body.read)
    rescue StandardError => e
      return [400, "Error parsing JSON request body: #{e}"]
    end

    return [400, 'Missing name payload key'] unless payload.is_a?(Hash) && payload.key?('name')

    return [409, ['A user with this name already exists']] if player_exists?(payload['name'])

    add_player(payload['name'])
  end

  def retrieve_player(uuid)
    ref = firestore.doc("players/#{uuid}")
    snapshot = ref.get
    return [404, headers, ['No such player']] unless snapshot.exists?

    [200, headers, [
      {
        name: snapshot.data[:name],
        game: snapshot.data[:game] || ''
      }.to_s
    ]]
  end
end
