# balboa

UCSD CSE 167 codebase  
https://cseweb.ucsd.edu/~tzli/cse167/

This is a revised version of balboa that builds on [SlangPy](https://github.com/shader-slang/slangpy). Currently only Homework 1 and 2 are completed. Future homeworks will be added soon.

# Setup

Clone the repository:

```bash
git clone https://github.com/BachiLi/balboa_slang_public.git
cd balboa_slang_public
```

We use [uv](https://docs.astral.sh/uv/) to manage Python packages and environments. Go to the linked website to install it if you haven't. Once installed, run:

```bash
uv sync
```

Then try:

```bash
uv run python main.py 1_1
```

You should see a window with white background.

# Platforms

Balboa depends on [SlangPy](https://github.com/shader-slang/slangpy) as a GPU programming framework, and should work on Windows, Linux, and Apple Silicon Macs.

**Intel Macs:** SlangPy does not currently publish macOS x86_64 wheels, so setup may require building SlangPy from source. If you are using an Intel Mac and `uv sync` fails because no compatible SlangPy package is available, you may need to build SlangPy from source. Contact the staff/instructor if you run into issues.

# CSE 167 Homework 2 - 3D Graphics

## Custom Scenes (HW 2.8)

For HW 2.8, we designed two custom 3D scenes using the rendering features implemented throughout the homework.

### 1. Purple Birthday Cake Scene

We created a custom purple birthday cake using 3D meshes and transformations. The cake consists of multiple cylindrical layers with different shades of purple, decorative frosting layers, and a candle on top.

The scene uses Phong lighting to create shading and depth, making the cake appear three-dimensional. We also added camera animation to show the cake from different angles.

- **Scene file:** `scenes/hw2/purple_cake_scene.json`
- **Mesh files:**
  - `scenes/hw2/cake_cylinder.json`
  - `scenes/hw2/cake_sphere.json`
  - `scenes/hw2/cake_cone.json`
- **Rendered image:** `outputs/purple_cake.png`

### 2. Ice Cream Scene

We created a custom 3D ice cream scene using geometric meshes and transformations. The scene consists of an ice cream scoop and a cone, modeled using separate mesh files.

The scene demonstrates 3D rendering techniques implemented throughout the homework, including mesh transformations, lighting, and depth testing.

- **Scene file:** `scenes/hw2/ice_cream_scene.json`
- **Mesh files:**
  - `scenes/hw2/ice_cream_cone.json`
  - `scenes/hw2/ice_cream_scoop.json`
- **Rendered image:** `outputs/ice_cream.png`

## Rendering the Scenes

### Purple Birthday Cake

To run the animated birthday cake scene:

```bash
uv run python main.py 2_7 scenes/hw2/purple_cake_scene.json
```

To generate the rendered image:

```bash
uv run python main.py --output outputs/purple_cake.png 2_7 scenes/hw2/purple_cake_scene.json
```

### Ice Cream

To run the ice cream scene:

```bash
uv run python main.py 2_7 scenes/hw2/ice_cream_scene.json
```

To generate the rendered image:

```bash
uv run python main.py --output outputs/ice_cream.png 2_7 scenes/hw2/ice_cream_scene.json
```

## Features Used

- **3D Meshes:** Constructed custom objects using geometric meshes.
- **Transformations:** Used translation, rotation, and scaling to position and resize objects.
- **Phong Lighting:** Applied ambient, diffuse, and specular lighting to shade the objects.
- **Animation:** Used camera transformation keyframes to create movement around the birthday cake.
- **Depth Testing:** Rendered overlapping 3D objects with proper depth handling.
- **Materials:** Applied different colors and material properties to the 3D objects.
