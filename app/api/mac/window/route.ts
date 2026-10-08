import { capture } from "@/lib/server/mac-windows";
import { OUR_HOSTS } from "@/lib/server/our-hosts"; // Fork-local: the server's public name counts as "this Mac"

export const dynamic = "force-dynamic";

/** A live picture of the window a bot is using on the user's Mac (?app=Calculator), for the previews. */
export async function GET(request: Request) {
  const url = new URL(request.url);
  if (!OUR_HOSTS.includes(url.hostname)) return new Response("local only", { status: 403 });
  const params = url.searchParams;
  const app = params.get("app");
  const max = Math.min(1280, Math.max(160, Number(params.get("max")) || 640));
  if (!app) return new Response("which app?", { status: 400 });
  try {
    const shot = await capture(app, max);
    if (!shot) return new Response("no window", { status: 404 });
    return new Response(new Uint8Array(shot.png), {
      headers: { "Content-Type": "image/png", "Cache-Control": "no-store", "X-Window-Title": encodeURIComponent(shot.title) },
    });
  } catch {
    return new Response("can't see that window", { status: 503 });
  }
}
