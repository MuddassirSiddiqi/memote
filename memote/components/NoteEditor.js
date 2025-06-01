// src/components/NoteEditor.js

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
