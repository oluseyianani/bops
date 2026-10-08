// Starts Next's standalone server from the repo root, as desktop/main.cjs does for the Mac app:
// server.js changes into its own folder on start, and Bops reads .data/, vm/ and edge/public from
// the working folder, so that change is turned off and the server runs here, where they are.
process.chdir = () => {};
require(require("node:path").join(__dirname, "..", ".next", "standalone", "server.js"));
