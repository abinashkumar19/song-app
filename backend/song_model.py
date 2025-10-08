from sqlalchemy import Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Song(Base):
    __tablename__ = 'songs'

    id = Column(Integer, primary_key=True, autoincrement=True)
    title = Column(String(255), nullable=False)
    artist = Column(String(255))
    url = Column(String(1024))

    def to_dict(self):
        return {"id": self.id, "title": self.title, "artist": self.artist, "url": self.url}
