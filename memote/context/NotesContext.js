// src/context/NotesContext.js

import React, { createContext, useState, useEffect } from "react";
import { v4 as uuidv4 } from "uuid";
import {
  loadNotesFromStorage,
  saveNotesToStorage,
} from "../utils/storage";

export const NotesContext = createContext(null);

export function NotesProvider({ children }) {
  const [notes, setNotes] = useState(() => loadNotesFromStorage());

  useEffect(() => {
    saveNotesToStorage(notes);
  }, [notes]);

  function createNote(title, content, reminder, tags) {
    const newNote = {
      id: uuidv4(),
      title,
      content,
      dateCreated: Date.now(),
      lastEdited: Date.now(),
      reminder,
      tags: [...tags],
    };
    setNotes(prev => [newNote, ...prev]);
  }

  function updateNote(id, data) {
    setNotes(prev =>
      prev.map(n => (n.id === id ? { ...n, ...data, lastEdited: Date.now() } : n))
    );
  }

  function deleteNote(id) {
    setNotes(prev => prev.filter(n => n.id !== id));
  }

  return (
    <NotesContext.Provider value={{ notes, createNote, updateNote, deleteNote }}>
      {children}
    </NotesContext.Provider>
  );
}
