import { defineConfig } from "vite";
import { viteSingleFile } from "vite-plugin-singlefile";
import coffee from "coffeescript";
import path from "node:path";
import fs from "node:fs";

// Minimal CoffeeScript support for Vite: compiles .coffee -> JS (with native
// ES import/export syntax, which CoffeeScript emits as-is) so Rollup/esbuild
// can handle module resolution/bundling just like any other ES module.
function coffeescriptPlugin() {
  return {
    name: "coffeescript",
    enforce: "pre",
    // Vite's dev server only transforms requests it recognizes as JS (known
    // extensions or an `?import` query). `.coffee` entry points referenced
    // straight from HTML would otherwise be served raw as text/coffeescript.
    configureServer(server) {
      server.middlewares.use((req, _res, next) => {
        const [pathname, query = ""] = req.url.split("?");
        if (pathname === "/") {
          req.url = "/index.html";
        } else if (pathname.endsWith(".coffee") && !/(^|&)import(&|=|$)/.test(query)) {
          req.url = `${pathname}?${query ? `${query}&` : ""}import`;
        }
        next();
      });
    },
    transform(code, id) {
      if (!id.endsWith(".coffee")) return null;
      const result = coffee.compile(code, {
        bare: true,
        sourceMap: true,
        filename: id,
      });
      return {
        code: result.js,
        map: result.v3SourceMap ? JSON.parse(result.v3SourceMap) : null,
      };
    },
  };
}

// The legacy vendor libs (signals, javascript-state-machine, chipmunk, zepto,
// underscore) are plain global-attaching scripts, loaded via <script src=...>
// pointing at node_modules. That works in dev (Vite serves node_modules), but
// node_modules isn't shipped in the dist output, so for a real single-file
// build we inline their file contents verbatim as a real <script> tag - same
// execution semantics (still runs as a classic script, still attaches to
// window), just embedded instead of referenced.
function inlineVendorScriptsPlugin() {
  return {
    name: "inline-vendor-scripts",
    apply: "build",
    transformIndexHtml(html) {
      return html.replace(
        /<script([^>]*)\ssrc="(node_modules\/[^"]+)"([^>]*)><\/script>/g,
        (match, before, src, after) => {
          const file = path.resolve(__dirname, src);
          if (!fs.existsSync(file)) {
            console.warn(
              `[inline-vendor-scripts] ${src} not found, leaving as external reference`,
            );
            return match;
          }
          const contents = fs.readFileSync(file, "utf-8");
          return `<script${before}${after}>\n${contents}\n</script>`;
        },
      );
    },
  };
}

// vite-plugin-singlefile requires a single rollup entry per build (it inlines
// all dynamic imports), so each page is built as its own pass, selected via
// `--mode`. `npm run build` chains both passes into the same dist/ dir.
const entries = {
  index: "index.html",
  highscore: "highscore.html",
};

export default defineConfig(({ mode }) => {
  const entry = entries[mode] ?? entries.index;

  return {
    resolve: {
      extensions: [".coffee", ".js", ".json"],
    },
    server: {
      // mDNS names, so phones on the same network/hotspot can reach the dev server
      allowedHosts: [".local"],
    },
    plugins: [coffeescriptPlugin(), viteSingleFile(), inlineVendorScriptsPlugin()],
    build: {
      outDir: "dist",
      emptyOutDir: entry === entries.index,
      cssCodeSplit: false,
      assetsInlineLimit: Infinity,
      rollupOptions: {
        input: path.resolve(__dirname, entry),
      },
    },
  };
});
