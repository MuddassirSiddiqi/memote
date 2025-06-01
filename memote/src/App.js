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
