import os
import time
from flask import Flask, jsonify, request
from flask_cors import CORS
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import OperationalError
from song_model import Base, Song

app = Flask(__name__)
CORS(app)

DATABASE_URL = os.environ.get('DATABASE_URL', 'sqlite:///songs.db')

for i in range(10):
    try:
        engine = create_engine(DATABASE_URL, echo=False, future=True)
        conn = engine.connect()
        conn.close()
        print("✅ Connected to database successfully!")
        break
    except OperationalError as e:
        print(f"❌ Database connection failed (attempt {i+1}/10): {e}")
        time.sleep(5)
else:
    raise Exception("Could not connect to database after multiple attempts")

Base.metadata.create_all(engine)
SessionLocal = sessionmaker(bind=engine)

@app.route('/')
def health():
    return jsonify({"status": "ok", "message": "Backend running"}), 200

@app.route('/api/songs', methods=['GET'])
def list_songs():
    session = SessionLocal()
    songs = session.query(Song).all()
    session.close()
    return jsonify([s.to_dict() for s in songs])

@app.route('/api/songs', methods=['POST'])
def add_song():
    data = request.json
    title = data.get('title')
    artist = data.get('artist')
    url = data.get('url')

    if not title:
        return jsonify({'error': 'Title is required'}), 400

    session = SessionLocal()
    new_song = Song(title=title, artist=artist, url=url)
    session.add(new_song)
    session.commit()
    result = new_song.to_dict()
    session.close()
    return jsonify(result), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
