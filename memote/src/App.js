import React from "react";
import { BrowserRouter as Router, Switch, Route, Redirect } from "react-router-dom";
import { NotesProvider } from "./context/NotesContext";
import Onboarding from "./components/Onboarding";
import NoteList from "./components/NoteList";
import NoteEditor from "./components/NoteEditor";
import "./App.css";

/**
 * App
 * Top-level component. Wraps children with NotesProvider.
 * Defines routes:
 * - "/"        → Onboarding
 * - "/notes"   → NoteList
 * - "/editor/:id" → NoteEditor
 * Any unknown route redirects to "/" (Onboarding).
 */
function App() {
  return (
    <NotesProvider>
      <Router>
        <Switch>
          <Route exact path="/">
            <Onboarding />
          </Route>
          <Route exact path="/notes">
            <NoteList />
          </Route>
          <Route exact path="/editor/:id">
            <NoteEditor />
          </Route>
          <Redirect to="/" />
        </Switch>
      </Router>
    </NotesProvider>
  );
}

export default App;
