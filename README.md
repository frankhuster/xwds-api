# xwds-api - Crosswords Game API

## REST API

### PUT /player

#### Request Payload

```JSON
{
  "name": "frankie"
}
```

#### Response Payload

```JSON
{
  "id": "{UUID}"
}
```

### GET /player/{UUID}

#### Response Payload

```JSON
{
  "name": "frankie",
  "game": "{UUID}" // or ""
}
```

### PUT /game

A player opens a new game

#### Request

```JSON
{
  "board_size": integer,
  "tray_size": integer,
  "number_of_players": integer,
  "player": "{UUID}"
}
```

#### Response

```JSON
{
  "id": "{UUID}", // game id
  "tray": "ABC..." // {tray_size} number of letters
}
```

### PUT /game/{UUID}

A player joins an open game

#### Request

```JSON
{
  "player": "{UUID}"
}
```

#### Response

```JSON
{
  "tray": "ABC..." // {tray_size} number of letters
}
```

### POST /game

A player hit the 'submit' button.

#### Request

```JSON
{
  "player": "{UUID}",
  "tray": "ABCDE", // up to {tray_size} letters
  "board": [ // up to {tray_size} elements, empty when swapping or passing
            { "row": 3, "col": 2, "letter": "D" },
            { "row": 3, "col": 3, "letter": "O" },
            { "row": 3, "col": 4, "letter": "G" }
  ]
}
```

#### Response - accepted word

```JSON
{
  "outcome": "accepted"
}
```

#### Response - rejected word

```JSON
{
  "outcome": "rejected",
  "message": "BORF is not in the dictionary"
}
```

### GET /word?WORD

Lookup a dictionary word

#### Response - HTTP 200 - word exists

```
  definition for the word
```

#### Response - HTTP 404 - word does not exist

```
  No such word
```

## Google Firestore Data Models

### /players/{player_uuid}

```JSON
{
  "id": "94BDF079-5B8C-4DBE-90F5-719864B54B48", // player_uuid
  "name": "frankie",
  "game": "01CB8759-6D63-4A85-BC76-8B7595FAEC3D" // or ""
}
```

### /games/{game_uuid}

Open game waiting for opponent(s)

```JSON
{
  "id": "01CB8759-6D63-4A85-BC76-8B7595FAEC3D", // game_uuid
  "status" : "open",
  "board_size": 7,
  "tray_size": 5,
  "number_of_players": 2,
  "players": [
    { // this player created the game
      "name": "karin",
      "order": 0
    }
  ],
```

Ongoing game

```JSON
{
  "id": "01CB8759-6D63-4A85-BC76-8B7595FAEC3D", // game_uuid
  "status" : "ongoing",
  "boardSize": 7,
  "traySize": 5,
  "number_of_players": 2,
  "players": [
    {
      "name": "frankie",
      "order": 1
    },
    {
      "name": "karin",
      "order": 0
    }
  ],
  "history": [ // one entry (aka turn) in the history per player, in order
    {
      "tray": "OGDHS" // karin (player with order 0) picked OGDHS
    },
    {
      "tray": "CAAIW" // frankie (player with order 1) picked CAAIW
    },
    {
      "board": [
        { "row": 3, "col": 2, "letter": "D" }, // karin played DOG...
        { "row": 3, "col": 3, "letter": "O" },
        { "row": 3, "col": 4, "letter": "G" }
      ],
      "tray": "HSLEN" // ...and picked LEN (on top of the remaining tray letters HS)
    },
    {
      "board": [
        { "row": 2, "col": 3, "letter": "C" }, // frankie played COW...
        { "row": 4, "col": 3, "letter": "W" }
      ],
      "tray": "AAIGQ" // ...and picked GQ
    },
    {
      "board": [],
      "tray": "ETNRB" // karin swapped
    },
    ...
  ]
}
```

Completed game

```JSON
{
  "id": "01CB8759-6D63-4A85-BC76-8B7595FAEC3D",
  "status" : "completed",
  "boardSize": 7,
  "traySize": 5,
  "number_of_players": 2,
  "players": [
    {
      "name": "frankie",
      "order": 1,
      "completion": "lost" // or forfeited
    },
    {
      "name": "karin",
      "order": 0,
      "completion": "won"
    }
  ],
  "history": [ ... ]
}
```

### /dictionary/{word}

The uppercase word is the document key

```JSON
{
  "description": "used to express disgust [interj]",
  "word": "AARGH"
}
```
