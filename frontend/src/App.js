import React, { useEffect, useState } from "react";

const backendUrl = "http://localhost:5000"; // Replace with backend public IP if deployed

function App() {
  const [songs, setSongs] = useState([]);
  const [title, setTitle] = useState("");
  const [artist, setArtist] = useState("");
  const [url, setUrl] = useState("");

  const fetchSongs = async () => {
    const res = await fetch(`${backendUrl}/api/songs`);
    const data = await res.json();
    setSongs(data);
  };

  const addSong = async () => {
    await fetch(`${backendUrl}/api/songs`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, artist, url }),
    });
    setTitle("");
    setArtist("");
    setUrl("");
    fetchSongs();
  };

  useEffect(() => {
    fetchSongs();
  }, []);

  return (
    <div style={{ padding: 20, fontFamily: "Arial" }}>
      <h1>🎶 Song App</h1>
      <div>
        <input placeholder="Title" value={title} onChange={e => setTitle(e.target.value)} />
        <input placeholder="Artist" value={artist} onChange={e => setArtist(e.target.value)} />
        <input placeholder="URL" value={url} onChange={e => setUrl(e.target.value)} />
        <button onClick={addSong}>Add Song</button>
      </div>
      <ul>
        {songs.map((s) => (
          <li key={s.id}>{s.title} — {s.artist}</li>
        ))}
      </ul>
    </div>
  );
}

export default App;
