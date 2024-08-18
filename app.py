from flask import Flask, jsonify, request

app = Flask(__name__)

# Sample game data for demonstration
games = [
    {"id": 1, "title": "Flappy Bird", "genre": "Arcade", "download_link": "https://example.com/download/flappybird.zip"},
    {"id": 2, "title": "Chess", "genre": "Strategy", "download_link": "https://example.com/download/chess.zip"}
]

@app.route('/')
def home():
    return jsonify(message="Welcome to your Game Library!")

@app.route('/games', methods=['GET'])
def list_games():
    return jsonify(games)

@app.route('/games/<int:game_id>', methods=['GET'])
def get_game(game_id):
    game = next((g for g in games if g["id"] == game_id), None)
    if game:
        return jsonify(game)
    else:
        return jsonify({"error": "Game not found"}), 404

@app.route('/games', methods=['POST'])
def add_game():
    new_game = request.json
    games.append(new_game)
    return jsonify(new_game), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
