# AI-Context-Generator
 
This Godot plugin is for conveniently copying all your scripts into one giant text block that you can easily paste into an AI.

![Untitled](https://github.com/rainlizard/AI-Context-Generator/assets/15337628/171f604f-cefa-4e14-b3d2-722f01afd2f4)


An API key isn't necessary here. I made this plugin to use with Claude Opus as you can fit your entire game into its token context window and then get very intelligent responses. The more context you feed an AI the better its answers will be.

This plugin can be used with ChatGPT Plus as well, but that one has a smaller context window so you might have to be more picky with the scripts you select. There's a Token estimator which may help you figure out if you're fitting into your AI's token context window.

# Quick guide
- Click the [AI button](https://github.com/rainlizard/AI-Context-Generator/assets/15337628/9d1f83b2-225d-48d7-a0f6-7f099d40d868) in the top right corner to open the AI-Context-Generator window.
- `File Types` and `Exclude directories` filter the display of your scripts that you can choose from
- Click `Select All` or manually click on scripts to select which ones you want to feed the AI
- Click `Send to Clipboard`, this will copy all the scripts so that you can right-click paste (or CTRL+V) them all at once.
- Click `Open URL` to go to your specified AI website and paste the script text along with your request like "code me a function that does X" or "optimize my code", etc.

To help the AI out, separators between scripts are automatically inserted into the text block. They look like this:
```
-------------------
# File: res://src/scenes/Player.gd
```
