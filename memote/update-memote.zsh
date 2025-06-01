#!/usr/bin/env zsh
#
# update-memote.zsh
#
# This script updates (or creates) all source files for the Memote React project,
# installs necessary dependencies, and ensures the code compiles without module-not-found errors.
#
# USAGE:
#   1. Save this file as update-memote.zsh inside the “memote/memote” folder (the one containing package.json).
#   2. Make it executable: chmod +x update-memote.zsh
#   3. Run it: ./update-memote.zsh
#
# It assumes:
#   - You are currently in the folder that contains package.json (e.g., D:/User/Desktop/ForGithub/memote/memote).
#   - Node.js and npm are installed and on PATH.
#

set -e

echo "─── 1. Installing / Updating Dependencies ───"
npm install react-router-dom react-datepicker uuid date-fns
npm install react-quill --legacy-peer-deps

echo "─── 2. Creating Directory Structure ───"
mkdir -p src/context
mkdir -p src/components
mkdir -p src/utils

echo "─── 3. Writing Utility Files (src/utils) ───"

cat << 'EOF' > src/utils/storage.js
/**
 * Key under which all notes are stored in localStorage.
 */
const NOTES_STORAGE_KEY = "memote_notes";

/**
 * Retrieve the array of notes from localStorage.
 * @returns {Array<Object>} An array of note objects, or an empty array if none exist.
 */
export function loadNotesFromStorage() {
  const stored = localStorage.getItem(NOTES_STORAGE_KEY);
  if (stored) {
    try {
      const parsed = JSON.parse(stored);
      return Array.isArray(parsed) ? parsed : [];
    } catch (error) {
      console.error("Error parsing notes from Local Storage:", error);
      return [];
    }
  }
  return [];
}

/**
 * Save the given notes array to localStorage.
 * @param {Array<Object>} notesArray
 */
export function saveNotesToStorage(notesArray) {
  try {
    const serialized = JSON.stringify(notesArray);
    localStorage.setItem(NOTES_STORAGE_KEY, serialized);
  } catch (error) {
    console.error("Error saving notes to Local Storage:", error);
  }
}
EOF

cat << 'EOF' > src/utils/htmlHelpers.js
/**
 * stripHtml
 * Removes all HTML tags from a string.
 * @param {string} htmlString
 * @returns {string} Plain text without HTML tags.
 */
export function stripHtml(htmlString) {
  if (typeof htmlString !== "string") {
    return "";
  }
  // Regex removes anything within angle brackets
  return htmlString.replace(/<[^>]+>/gi, "");
}
EOF

echo "─── 4. Writing Context File (src/context/NotesContext.js) ───"

cat << 'EOF' > src/context/NotesContext.js
import React, { createContext, useState, useEffect } from "react";
import { v4 as uuidv4 } from "uuid";
import {
  loadNotesFromStorage,
  saveNotesToStorage,
} from "../utils/storage";

/**
 * Note object shape:
 * {
 *   id: string,
 *   title: string,
 *   content: string,         // rich-text HTML
 *   dateCreated: number,     // Unix timestamp (ms)
 *   lastEdited: number,      // Unix timestamp (ms)
 *   reminder: number | null, // Unix timestamp (ms) or null if no reminder
 *   tags: Array<string>
 * }
 */

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
EOF

echo "─── 5. Writing Component Files (src/components) ───"

# 5.1 Onboarding
cat << 'EOF' > src/components/Onboarding.js
import React from "react";
import { useNavigate } from "react-router-dom";
import "./Onboarding.css";

export default function Onboarding() {
  const navigate = useNavigate();

  function handleContinue() {
    navigate("/notes");
  }

  return (
    <div className="onboarding-container">
      <div className="onboarding-banner">
        <h1 className="onboarding-title">
          Memote<br/>Your Personal Note Diary
        </h1>
        <p className="onboarding-subtitle">
          Effortlessly capture and organize your thoughts, tasks, and ideas. Simplify your life 
          with powerful features like tagging and synchronization. Start your note-taking 
          journey now.
        </p>
        <button className="onboarding-button" onClick={handleContinue}>
          Continue
        </button>
      </div>
    </div>
  );
}
EOF

cat << 'EOF' > src/components/Onboarding.css
.onboarding-container {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100vh;
  background-color: #e0f7fa;
}

.onboarding-banner {
  background-color: #ffffff;
  border-radius: 12px;
  padding: 32px;
  max-width: 512px;
  text-align: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.onboarding-title {
  font-size: 2rem;
  font-weight: bold;
  margin-bottom: 1rem;
  line-height: 1.2;
}

.onboarding-subtitle {
  font-size: 1rem;
  margin-bottom: 2rem;
  color: #555555;
  line-height: 1.5;
}

.onboarding-button {
  background-color: #00bfa5;
  color: #ffffff;
  border: none;
  border-radius: 24px;
  padding: 12px 32px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.2s ease-in-out;
}

.onboarding-button:hover {
  background-color: #009e88;
}
EOF

# 5.2 Header
cat << 'EOF' > src/components/Header.js
import React, { useState, useContext } from "react";
import { NotesContext } from "../context/NotesContext";
import "./Header.css";

export default function Header({ onSearch }) {
  const [searchQuery, setSearchQuery] = useState("");
  const { notes } = useContext(NotesContext); // demonstration of context usage

  function handleInputChange(e) {
    const newQuery = e.target.value;
    setSearchQuery(newQuery);
    if (typeof onSearch === "function") {
      onSearch(newQuery);
    }
  }

  return (
    <header className="header-container">
      <div className="header-left">
        <h2 className="header-greeting">Hi, Muddassir</h2>
      </div>
      <div className="header-center">
        <input
          type="text"
          placeholder="Search for notes"
          value={searchQuery}
          onChange={handleInputChange}
          className="header-search-input"
        />
      </div>
      <div className="header-right">
        <div className="header-bell-icon">🔔</div>
      </div>
    </header>
  );
}
EOF

cat << 'EOF' > src/components/Header.css
.header-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  background-color: #ffffff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.header-greeting {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 500;
  color: #333333;
}

.header-search-input {
  width: 320px;
  padding: 8px 12px;
  font-size: 1rem;
  border: 1px solid #cccccc;
  border-radius: 24px;
  outline: none;
  transition: border-color 0.2s ease-in-out;
}

.header-search-input:focus {
  border-color: #00bfa5;
}

.header-bell-icon {
  font-size: 1.5rem;
  cursor: pointer;
}
EOF

# 5.3 DateSelector
cat << 'EOF' > src/components/DateSelector.js
import React, { useState, useEffect } from "react";
import { addDays, startOfWeek, isSameDay } from "date-fns";
import "./DateSelector.css";

export default function DateSelector({ onDateSelect, initialDate }) {
  const effectiveInitialDate = initialDate || new Date();
  const [selectedDate, setSelectedDate] = useState(effectiveInitialDate);
  const [weekDates, setWeekDates] = useState([]);

  function computeWeekDates(refDate) {
    const startMonday = startOfWeek(refDate, { weekStartsOn: 1 });
    const arr = [];
    for (let i = 0; i < 7; i++) {
      arr.push(addDays(startMonday, i));
    }
    return arr;
  }

  useEffect(() => {
    setWeekDates(computeWeekDates(selectedDate));
  }, [selectedDate]);

  function handleDateClick(dateObj) {
    setSelectedDate(dateObj);
    if (typeof onDateSelect === "function") {
      onDateSelect(dateObj);
    }
  }

  return (
    <div className="date-selector-container">
      {weekDates.map(dateObj => {
        const dayOfMonth = dateObj.getDate();
        const dayOfWeekShort = dateObj.toLocaleDateString("en-US", {
          weekday: "short",
        });
        const isSelected = isSameDay(dateObj, selectedDate);

        return (
          <button
            key={dateObj.toISOString()}
            className={
              "date-selector-button " + (isSelected ? "selected" : "")
            }
            onClick={() => handleDateClick(dateObj)}
          >
            <span className="date-selector-weekday">{dayOfWeekShort}</span>
            <span className="date-selector-day">{dayOfMonth}</span>
          </button>
        );
      })}
    </div>
  );
}
EOF

cat << 'EOF' > src/components/DateSelector.css
.date-selector-container {
  display: flex;
  overflow-x: auto;
  padding: 8px 16px;
  background-color: #f7f7f7;
}

.date-selector-button {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  margin-right: 8px;
  border: none;
  border-radius: 12px;
  background-color: #ffffff;
  cursor: pointer;
  transition: background-color 0.2s ease-in-out;
}

.date-selector-button.selected {
  background-color: #00bfa5; /* teal for selected */
  color: #ffffff;
}

.date-selector-weekday {
  font-size: 0.75rem;
  font-weight: 500;
}

.date-selector-day {
  font-size: 1.25rem;
  font-weight: bold;
}
EOF

# 5.4 NoteCard
cat << 'EOF' > src/components/NoteCard.js
import React from "react";
import { useNavigate } from "react-router-dom";
import { stripHtml } from "../utils/htmlHelpers";
import "./NoteCard.css";

export default function NoteCard({ note }) {
  const navigate = useNavigate();
  const { id, title, content, lastEdited, tags } = note;

  const plainTextPreview = stripHtml(content).slice(0, 80);
  const lastEditedFormatted = new Date(lastEdited).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });

  function handleCardClick() {
    navigate(`/editor/${id}`);
  }

  return (
    <div className="note-card-container" onClick={handleCardClick}>
      <div className="note-card-header">
        <h3 className="note-card-title">{title}</h3>
        <span className="note-card-last-edited">
          Edited: {lastEditedFormatted}
        </span>
      </div>
      <p className="note-card-preview">{plainTextPreview}…</p>
      <div className="note-card-tags">
        {tags.map(tag => (
          <span
            key={tag}
            className={"note-card-tag tag-" + tag.toLowerCase().replace(/\s+/g, "-")}
          >
            {tag}
          </span>
        ))}
      </div>
    </div>
  );
}
EOF

cat << 'EOF' > src/components/NoteCard.css
.note-card-container {
  background-color: #ffffff;
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 16px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: transform 0.1s ease-in-out, box-shadow 0.2s ease-in-out;
}

.note-card-container:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.note-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.note-card-title {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 600;
  color: #333333;
}

.note-card-last-edited {
  font-size: 0.75rem;
  color: #777777;
}

.note-card-preview {
  margin: 8px 0;
  color: #555555;
  font-size: 0.95rem;
  line-height: 1.3;
}

.note-card-tags {
  margin-top: 8px;
  display: flex;
  flex-wrap: wrap;
}

.note-card-tag {
  font-size: 0.75rem;
  padding: 4px 8px;
  border-radius: 8px;
  margin-right: 8px;
  margin-bottom: 4px;
  color: #ffffff;
}

/* Tag colors—match these to your AVAILABLE_TAGS in NoteEditor */
.tag-important {
  background-color: #e53935;
}
.tag-should-be-done-this-week {
  background-color: #fb8c00;
}
.tag-top-priority {
  background-color: #8e24aa;
}
.tag-complete-now {
  background-color: #43a047;
}
EOF

# 5.5 NoteList
cat << 'EOF' > src/components/NoteList.js
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
EOF

cat << 'EOF' > src/components/NoteList.css
.note-list-page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: #f1f5f6;
}

.note-list-container {
  flex: 1;
  padding: 16px 24px;
  overflow-y: auto;
}

.no-notes-message {
  margin-top: 48px;
  text-align: center;
  color: #777777;
  font-size: 1rem;
}

.note-list-add-button {
  position: fixed;
  bottom: 32px;
  right: 32px;
  width: 64px;
  height: 64px;
  border: none;
  border-radius: 32px;
  background-color: #00bfa5;
  color: #ffffff;
  font-size: 2rem;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  transition: transform 0.1s ease-in-out, background-color 0.2s ease-in-out;
}

.note-list-add-button:hover {
  background-color: #009e88;
  transform: translateY(-2px);
}
EOF

# 5.6 TagButton
cat << 'EOF' > src/components/TagButton.js
import React from "react";
import "./TagButton.css";

export default function TagButton({ label, isSelected, onToggle }) {
  function handleClick() {
    if (typeof onToggle === "function") onToggle();
  }

  const className = isSelected
    ? "tag-button tag-button-selected"
    : "tag-button";

  return (
    <button className={className} onClick={handleClick}>
      {label}
    </button>
  );
}
EOF

cat << 'EOF' > src/components/TagButton.css
.tag-button {
  background-color: #e0e0e0;
  border: none;
  border-radius: 16px;
  padding: 8px 16px;
  margin-right: 8px;
  margin-bottom: 8px;
  font-size: 0.875rem;
  cursor: pointer;
  transition: background-color 0.2s ease-in-out;
  color: #333333;
}

.tag-button-selected {
  background-color: #00bfa5;
  color: #ffffff;
}
EOF

# 5.7 NoteEditor
cat << 'EOF' > src/components/NoteEditor.js
import React, { useState, useContext, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import ReactQuill from "react-quill";
import DatePicker from "react-datepicker";
import { NotesContext } from "../context/NotesContext";
import TagButton from "./TagButton";
import "react-quill/dist/quill.snow.css";
import "react-datepicker/dist/react-datepicker.css";
import "./NoteEditor.css";

const AVAILABLE_TAGS = [
  "Important",
  "Should Be Done This Week",
  "Top Priority",
  "Complete Now",
];

export default function NoteEditor() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { notes, createNote, updateNote, deleteNote } = useContext(NotesContext);
  const isNewNote = id === "new";

  const [noteTitle, setNoteTitle] = useState("");
  const [noteContent, setNoteContent] = useState("");
  const [noteReminder, setNoteReminder] = useState(null);
  const [noteTags, setNoteTags] = useState([]);
  const [lastEditedTimestamp, setLastEditedTimestamp] = useState(null);

  useEffect(() => {
    if (!isNewNote) {
      const existing = notes.find(n => n.id === id);
      if (existing) {
        setNoteTitle(existing.title);
        setNoteContent(existing.content);
        setNoteReminder(existing.reminder ? new Date(existing.reminder) : null);
        setNoteTags(Array.isArray(existing.tags) ? existing.tags : []);
        setLastEditedTimestamp(existing.lastEdited);
      } else {
        navigate("/notes", { replace: true });
      }
    }
  }, [id, isNewNote, notes, navigate]);

  function handleTitleChange(e) {
    setNoteTitle(e.target.value);
  }

  function handleContentChange(htmlValue) {
    setNoteContent(htmlValue);
  }

  function handleTagToggle(tagLabel) {
    setNoteTags(prev =>
      prev.includes(tagLabel) ? prev.filter(t => t !== tagLabel) : [...prev, tagLabel]
    );
  }

  function handleReminderChange(dateObj) {
    setNoteReminder(dateObj);
  }

  function handleSave() {
    if (noteTitle.trim() === "") {
      alert("Title cannot be empty.");
      return;
    }

    if (isNewNote) {
      createNote(
        noteTitle,
        noteContent,
        noteReminder ? noteReminder.getTime() : null,
        noteTags
      );
    } else {
      updateNote(id, {
        title: noteTitle,
        content: noteContent,
        reminder: noteReminder ? noteReminder.getTime() : null,
        tags: noteTags,
      });
    }
    navigate("/notes");
  }

  function handleDelete() {
    if (!isNewNote) {
      const confirmDelete = window.confirm("Permanently delete this note?");
      if (confirmDelete) {
        deleteNote(id);
        navigate("/notes");
      }
    }
  }

  function handleCancel() {
    navigate("/notes");
  }

  const lastEditedFormatted =
    lastEditedTimestamp !== null
      ? new Date(lastEditedTimestamp).toLocaleString("en-US", {
          month: "short",
          day: "numeric",
          year: "numeric",
          hour: "numeric",
          minute: "2-digit",
        })
      : "";

  const quillModules = {
    toolbar: [
      [{ header: [1, 2, 3, false] }],
      ["bold", "italic", "underline", "strike"],
      [{ list: "ordered" }, { list: "bullet" }],
      [{ align: [] }],
      ["clean"],
    ],
  };

  const quillFormats = [
    "header",
    "bold",
    "italic",
    "underline",
    "strike",
    "list",
    "bullet",
    "align",
  ];

  return (
    <div className="note-editor-page">
      <div className="note-editor-header">
        <input
          type="text"
          className="note-editor-title-input"
          placeholder="Note Title"
          value={noteTitle}
          onChange={handleTitleChange}
        />
      </div>

      <div className="note-editor-toolbar-spacer" />

      <div className="note-editor-quill-container">
        <ReactQuill
          value={noteContent}
          onChange={handleContentChange}
          modules={quillModules}
          formats={quillFormats}
          placeholder="Start writing your note..."
        />
      </div>

      <div className="note-editor-details">
        <div className="note-editor-reminder">
          <label className="note-editor-label">Reminder:</label>
          <DatePicker
            selected={noteReminder}
            onChange={handleReminderChange}
            showTimeSelect
            dateFormat="Pp"
            className="note-editor-datepicker"
            placeholderText="No reminder set"
          />
        </div>
        <div className="note-editor-tags">
          <label className="note-editor-label">Tags:</label>
          <div className="tag-buttons-container">
            {AVAILABLE_TAGS.map(tagLabel => {
              const isSelected = noteTags.includes(tagLabel);
              return (
                <TagButton
                  key={tagLabel}
                  label={tagLabel}
                  isSelected={isSelected}
                  onToggle={() => handleTagToggle(tagLabel)}
                />
              );
            })}
          </div>
        </div>
      </div>

      <div className="note-editor-footer">
        <div className="note-editor-footer-left">
          {lastEditedFormatted && (
            <span className="note-editor-last-edited">
              Last edited: {lastEditedFormatted}
            </span>
          )}
        </div>
        <div className="note-editor-footer-right">
          <button className="note-editor-save-button" onClick={handleSave}>
            Save
          </button>
          {!isNewNote && (
            <button className="note-editor-delete-button" onClick={handleDelete}>
              Delete
            </button>
          )}
          <button className="note-editor-cancel-button" onClick={handleCancel}>
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}
EOF

cat << 'EOF' > src/components/NoteEditor.css
.note-editor-page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: #fafafa;
}

.note-editor-header {
  background-color: #ffffff;
  padding: 16px 24px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.note-editor-title-input {
  width: 100%;
  font-size: 1.5rem;
  font-weight: 600;
  padding: 8px 12px;
  border: none;
  border-bottom: 2px solid #cccccc;
  outline: none;
  transition: border-color 0.2s ease-in-out;
}

.note-editor-title-input:focus {
  border-bottom-color: #00bfa5;
}

.note-editor-toolbar-spacer {
  height: 8px;
}

.note-editor-quill-container {
  flex: 1;
  overflow-y: auto;
  padding: 16px 24px;
}

.note-editor-details {
  background-color: #ffffff;
  padding: 16px 24px;
  display: flex;
  flex-wrap: wrap;
  gap: 24px;
  border-top: 1px solid #dddddd;
}

.note-editor-reminder,
.note-editor-tags {
  display: flex;
  flex-direction: column;
}

.note-editor-label {
  font-size: 0.875rem;
  font-weight: 500;
  margin-bottom: 8px;
  color: #333333;
}

.note-editor-datepicker {
  width: 240px;
  padding: 8px 12px;
  font-size: 1rem;
  border: 1px solid #cccccc;
  border-radius: 8px;
  outline: none;
}

.tag-buttons-container {
  display: flex;
  flex-wrap: wrap;
}

.note-editor-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  background-color: #ffffff;
  border-top: 1px solid #dddddd;
}

.note-editor-last-edited {
  font-size: 0.75rem;
  color: #777777;
}

.note-editor-footer-right {
  display: flex;
  gap: 12px;
}

.note-editor-save-button,
.note-editor-delete-button,
.note-editor-cancel-button {
  padding: 8px 16px;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: background-color 0.2s ease-in-out;
}

.note-editor-save-button {
  background-color: #00bfa5;
  color: #ffffff;
}

.note-editor-save-button:hover {
  background-color: #009e88;
}

.note-editor-delete-button {
  background-color: #e53935;
  color: #ffffff;
}

.note-editor-delete-button:hover {
  background-color: #c62828;
}

.note-editor-cancel-button {
  background-color: #757575;
  color: #ffffff;
}

.note-editor-cancel-button:hover {
  background-color: #616161;
}
EOF

echo "─── 6. Overwriting Main Entry Files ───"

# 6.1 App.js
cat << 'EOF' > src/App.js
import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { NotesProvider } from "./context/NotesContext";
import Onboarding from "./components/Onboarding";
import NoteList from "./components/NoteList";
import NoteEditor from "./components/NoteEditor";
import "./App.css";

/**
 * App
 * Top-level component. Wraps children with NotesProvider.
 * Defines routes using React Router v6:
 *  "/"            → Onboarding
 *  "/notes"       → NoteList
 *  "/editor/:id"  → NoteEditor
 * Any unknown route redirects to "/".
 */
function App() {
  return (
    <NotesProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Onboarding />} />
          <Route path="/notes" element={<NoteList />} />
          <Route path="/editor/:id" element={<NoteEditor />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </NotesProvider>
  );
}

export default App;
EOF

# 6.2 App.css
cat << 'EOF' > src/App.css
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen,
    Ubuntu, Cantarell, "Open Sans", "Helvetica Neue", sans-serif;
  background-color: #f1f5f6;
  color: #222222;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, "Courier New", monospace;
}
EOF

# 6.3 index.js
cat << 'EOF' > src/index.js
import React from "react";
import ReactDOM from "react-dom";
import App from "./App";
import "./index.css";

/**
 * Standard ReactDOM render call.
 */
ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById("root")
);
EOF

# 6.4 index.css
cat << 'EOF' > src/index.css
/* Global resets & basic theming */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html,
body,
#root {
  height: 100%;
}
EOF

echo "─── 7. Final Installation & Message ───"
npm install

echo "✔ All files have been updated. Your Memote React application is now fully configured."
echo "✔ Run 'npm start' (or 'npm run dev' if you added that alias) to launch the development server."
