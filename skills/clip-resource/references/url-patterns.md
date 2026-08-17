# URL patterns by content type

The URL pattern is the second branch in Step 2's detection logic. Use these patterns as a starting hypothesis. They're strong signals but not infallible, so always cross-check against schema.org and user-stated type before deciding.

## Article

Articles are long-form content from standalone blogs, personal websites, or independent publishers. Patterns:

- Medium posts: `medium.com/@...` or `medium.com/...`
- Substack: `substack.com/` domains or custom domains under `substack.com`
- Dev.to: `dev.to/...`
- Personal blogs: custom domains with a post-like URL structure (`/blog/...`, `/articles/...`, `/posts/...`)
- Independent publisher sites: similar post-like patterns

## News

News articles come from established news outlets, wire services, and news aggregators. Patterns:

- Major outlets: `nytimes.com`, `theguardian.com`, `bbc.com/news`, `cnn.com`, `washingtonpost.com`, `npr.org`
- Wire services: `reuters.com`, `apnews.com`, `associated-press.org`
- Regional news: news outlets tied to specific regions or cities
- News aggregators: `news.ycombinator.com`, `techmeme.com`

## Social/Forum thread

Social posts and threaded discussions live on platforms where community participation is the primary interaction. Patterns:

- Reddit: `reddit.com/r/.../comments/...`
- Twitter/X: `x.com/...` or `twitter.com/status/...`
- Mastodon: `mastodon.social/@.../...` or other Mastodon instances
- Threads (Meta): `threads.net/@.../...`
- Forums: domain-specific forum patterns like `forums.something.com/...` or `discourse.example.com/t/...`
- Discussion threads: any platform with a thread-like URL containing thread ID or slug

## Video

Video content lives on video hosting platforms. Patterns:

- YouTube: `youtube.com/watch?v=...` or `youtu.be/...`
- Vimeo: `vimeo.com/...`
- TikTok: `tiktok.com/@.../video/...`
- Instagram Reels: `instagram.com/reel/...`
- Loom: `loom.com/share/...`
- Other video hosts: platform-specific video URL formats
