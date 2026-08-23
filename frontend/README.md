# Nothing Happens frontend

This package is a standalone Svelte UI shell. It currently uses view-layer mock data and does not
connect to Godot or define an IPC protocol.

## Development preview

```sh
pnpm dev
```

The root page has a development-only selector for Office, Dialogue, Parliament, and Constitution.
The standalone component gallery is available at `/components`.

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
