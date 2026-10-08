import "server-only";

/**
 * Fork-local (see FORK.md): the names a request from the app's own page arrives under. On a Mac that
 * is loopback only. Self-hosted on a server behind Caddy, the page is served as BOPS_PUBLIC_HOST, so
 * routes that are "for this Mac only" (phone, lines, call, vnc, mac) take that name too, the same
 * names proxy.ts already lets through. The Host header is the caller's to set, so this stops
 * browsers, not a determined caller: Caddy's basic auth is what keeps strangers out.
 */
export const OUR_HOSTS: string[] = [
  "localhost",
  "127.0.0.1",
  "::1",
  ...(process.env.BOPS_PUBLIC_HOST ?? "")
    .split(",")
    .map((h) => h.trim().replace(/:\d+$/, "").toLowerCase())
    .filter(Boolean),
];
