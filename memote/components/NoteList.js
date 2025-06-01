// src/components/NoteList.js

import React, { useContext, useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { NotesContext } from "../context/NotesContext";
import Header from "./Header";
import DateSelector from "./DateSelector";
import NoteCard from "./NoteCard";
import { stripHtml } from "../utils/htmlHelpers";
import "./NoteList.css";

export default function NoteList() {
  const { notes } = useContext(NotesContext);
  const navigate = useNavigate();

  const [selectedDate, setSelectedDate] = useState(new Date());
  const [searchQuery, setSearchQuery] = useState("");
  const [filteredNotes, setFilteredNotes] = useState([]);

  function filterNotes() {
    const startOfDay = new Date(
      selectedDate.getFullYear(),
      selectedDate.getMonth(),
      selectedDate.getDate(),
      0,
      0,
      0,
      0
    ).getTime();
    const endOfDay = new Date(
      selectedDate.getFullYear(),
      selectedDate.getMonth(),
      selectedDate.getDate(),
      23,
      59,
      59,
      999
    ).getTime();

    const lowerSearch = searchQuery.toLowerCase();

    const result = notes.filter(note => {
      const created = note.dateCreated;
      const sameDay = created >= startOfDay && created <= endOfDay;

      const titleMatches = note.title.toLowerCase().includes(lowerSearch);
      const contentPlain = stripHtml(note.content).toLowerCase();
      const contentMatches = contentPlain.includes(lowerSearch);

      return sameDay && (titleMatches || contentMatches);
    });

    setFilteredNotes(result);
  }

  useEffect(() => {
    filterNotes();
  }, [notes, selectedDate, searchQuery]);

  function handleAddNew() {
    navigate("/editor/new");
  }

  function handleDateSelect(date) {
    setSelectedDate(date);
  }

  function handleSearch(query) {
    setSearchQuery(query);
  }

  return (
    <div className="note-list-page">
      <Header onSearch={handleSearch} />
      <DateSelector onDateSelect={handleDateSelect} initialDate={selectedDate} />
      <div className="note-list-container">
        {filteredNotes.length === 0 ? (
          <div className="no-notes-message">
            No notes found for the selected date or search query.
          </div>
        ) : (
          filteredNotes.map(note => <NoteCard key={note.id} note={note} />)
        )}
      </div>
      <button className="note-list-add-button" onClick={handleAddNew}>
        +
      </button>
    </div>
  );
}
