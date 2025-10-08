import React, { useEffect, useState } from 'react';
import axios from 'axios';

function App() {
  const [songs, setSongs] = useState([]);
  const [title, setTitle] = useState('');
  const [artist, setArtist] = useState('');
  const [url, setUrl] = useState('');

  useEffect(() => {
    axios.get('http://backend:5000/api/songs')
      .then(res => setSongs(res.data))
      .catch(err => console.error(err));
  }, []);

  const addSong = () => {
    axios.post('http://backend:5000/api/songs', { title, artist, url })
      .then(res => setSongs([...songs, res.data]))
      .catch(err => console.error(err));
  }

  return (
    <div>
      <h1>Song App</h1>
      <input placeholder="Title" value={title} onChange={e => setTitle(e.target.value)} />
      <input placeholder="Artist" value={artist} onChange={e => setArtist(e.target.value)} />
      <input placeholder="URL" value={url} onChange={e => setUrl(e.target.value)} />
      <button onClick={addSong}>Add Song</button>
      <ul>
        {songs.map(s => <li key={s.id}>{s.title} - {s.artist}</li>)}
      </ul>
    </div>
  );
}

export default App;
