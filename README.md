# Mike the Pedagogical Agent

Welcome to the official repository of **Mike The Pedagogical Agent** v3.0 now powered by Godot.

This project started as a Unity3D project, originally created for a CentraleSupelec Lecture on Artificial Intelligence and Social Sciences.

This project contains the foundation of a Socially Interactive Agent or Embodied Conversational Agent.
It is greatly inspired by other projects such as Greta, Marc and the Virtual Human Toolkit.
It was not really designed to fully reproduce the capacity of a SIA, but to offer an easy way for students to discover how an agent can work.

Actual version uses Avaturn 3D Models.

# Installation

You can clone the current project using your favorite Git Client or you can download it as a zip archive and extract it on your drive.

Mike the PA should work on Linux, Windows and MacOS versions of Godot starting from version 4.6.

For the TextToSpeech, it uses [Piper-TTS](https://github.com/OHF-Voice/piper1-gpl). You can follow their instructions to install Piper-TTS, to download voices and to serve them locally.

For the SpeechToText, it uses [Godot Whisper](https://github.com/V-Sekai/godot-whisper). The default tiny.en model for english is provided but downloading additional (and bigger) language models can be done from [huggingfaces](https://huggingface.co/collections/openai/whisper-release)

As a Godot project, you need to add the project in your project's list using Godot "Import" functionality.

# Usage

Once the project opened in Godot, open the *main.tscn* file to load the default scene. If you are familiar with Godot, you should get around quite easily.

By default, the agent expects that Piper-TTS is serving a voice model at **http://localhost:5000** and that Ollama is serving a *llama3.2:latest* model at **http://localhost:11434**.

The *main.tscn* scene only has a fake background, a Camera, some lighting and our agent. The agent is a Node equipped with custom scripts in order to allow him to :
- Run a dialog using an external LLM (start and stop recording your voice with the SpaceBar, the agent will then reply).  
- Follow an object with its gaze (by default, the camera)
- Perform some pre-rendered animations (downloaded from Mixamo)
- Do basic lip animation mixed with facial expressions while there is audio playing

The project is quite light and straightforward. It does not compete with other exising agent plaforms such as [Greta](https://github.com/isir/greta), Marc or [VHTK](https://vhtoolkit.ict.usc.edu/) but can be a good playground to manipulate an interactive character.


If you use **Mike the Pedagogical Agent** in one of your projects, citing this repository is appreciated.

Copyright. Brian Ravenet