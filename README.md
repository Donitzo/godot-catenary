# godot-catenary

A dynamic catenary node and shader for [Godot engine](https://godotengine.org/) (for hanging chains, ropes etc.).

> In physics and geometry, a catenary is the curve that an idealized hanging chain or cable assumes under its own weight when supported only at its ends in a uniform gravitational field
> 
> <cite>[Wiki](https://en.wikipedia.org/wiki/Catenary)</cite>

Example of the node in action:

# ![Preview](https://github.com/Donitzo/godot-catenary/blob/main/images/preview.gif)

## About

The idea came from [this excellent tutorial](https://www.alanzucconi.com/2020/12/13/catenary-1/) by Alan Zucconi, in which he describes the math behind catenaries. I used these formulas plus some original ideas to implement a new catenary node type in Godot.

Notable improvements are:

1. The model will be scaled evenly along the entire curve
2. Support for swinging catenaries
3. GPU-driven rendering and animations

## How to use

This repository contains a demo Godot project in the src folder which will demonstrate the usage of the catenary node. To use the node in your own project, simply Copy these two files:

```
# scripts/catenary.gd - The GDScript
# shaders/catenary.tres - The shader
```

The Catenary node acts as the starting point for the curve. The _target path_ points towards another node which will act as the end point of the curve.

The catenary node can be used ingame or in the editor, as it is a tool.

There are a number of parameters to set before the node works:

```
# The mesh with the rope-like object spanning the x-axis
mesh

# The end point target
target_path

# Whether to track the target node ingame using process
track_target

# The real-world length of the catenary (limited by the distance between the start/end point)
length

# The scale multiplier of the yz-axes of the mesh
width

# The catenary swing angle in radians
swing_angle

# The catenary swing frequency
swing_frequency
```

The length parameter adjusts the actual length of the cable/rope. If the length is longer than the distance between the start and end point, the curve will sag.

# ![Hanging cables](https://github.com/Donitzo/godot-catenary/blob/main/images/screenshot2.png)

## Last words

I hope you find this tool useful. Please raise an issue if you discover a bug or just have general feedback.
