# Display Vector3D 

[![Godot Version](https://img.shields.io/badge/Godot-4.x-blue?style=for-the-badge&logo=godot-engine)](https://godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)


A lightweight Godot 4.x addon to visualize 3D vectors directly in the editor or during runtime.
Perfect for debugging player movement, AI steering, or physics directions.

![Display Vector3D Preview](./example_screenshot.png)

# ✨ Features

Draws vector lines (arrows) in 3D space

Customizable color, length, and thickness

Works in both editor and runtime

Minimal performance overhead

Easy to toggle on/off for debug builds

# 📦 Installation

Copy the `display_vector3d/` folder into your project’s `res://addons/` directory

In Godot, go to Project → Project Settings → Plugins

Enable Display Vector3D

# ⚙️ Usage

Once enabled, you can use it directly in your scripts.

Example:

```
var velocity = Vector3(1, 0, 2)
DisplayVector3D.draw_vector(global_position, velocity.normalized() * 2, Color(0, 1, 0))
```

