# Nothing Happens frontend

This package provides the Svelte UI used by Godot CEF and a standalone browser demo.

## Development preview

```sh
pnpm dev
```

The root page has a development-only selector for Office, Dialogue, Parliament, and Constitution.
The standalone component gallery is available at `/components`.

## Run with Godot

1. Install [godot-cef v1.15.3](https://github.com/dsh0416/godot-cef/releases/tag/v1.15.3) so the addon is located at `../godot/addons/godot_cef`.
2. Install dependencies and build the frontend into the Godot project:

   ```sh
   pnpm install
   pnpm build:godot
   ```

3. Open `../godot/project.godot` in Godot and run the project.

`pnpm build:godot` rebuilds the frontend, removes the previous `godot/web`, and copies `frontend/build` into it. The generated directory is ignored by Git.

## Verification

```sh
pnpm test
pnpm run check
pnpm run lint
```

## Original Svelte scaffold notes

Everything you need to build a Svelte project, powered by [`sv`](https://github.com/sveltejs/cli).

## Creating a project

If you're seeing this, you've probably already done this step. Congrats!

```sh
# create a new project
npx sv create my-app
```

To recreate this project with the same configuration:

```sh
# recreate this project
pnpm dlx sv@0.17.0 create --template minimal --types ts --add prettier eslint sveltekit-adapter="adapter:static" --install pnpm frontend
```

## Developing

Once you've created a project and installed dependencies with `npm install` (or `pnpm install` or `yarn`), start a development server:

```sh
npm run dev

# or start the server and open the app in a new browser tab
npm run dev -- --open
```

## Building

To create a production version of your app:

```sh
npm run build
```

You can preview the production build with `npm run preview`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.
