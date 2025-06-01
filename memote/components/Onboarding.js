// src/components/Onboarding.js

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
