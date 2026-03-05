# Media Assets

Real images make or break a website. Placeholder boxes and gray rectangles signal "unfinished". Use stock photos and AI-generated imagery during development — not after.

## Stock Photography (Pexels / Unsplash MCP)

When an MCP server for stock photos is available, use it proactively:

- **Search contextually** — don't use generic keywords. Instead of "office", use "modern tech startup office Austin Texas" or "diverse team whiteboard brainstorming"
- **Match the aesthetic** — dark mode site? Search for moody, low-key photography. Bright SaaS? Search for well-lit, clean compositions
- **People add credibility** — team photos, founder portraits, and candid work shots signal authenticity. Prefer authentic-looking over staged corporate
- **Download and place immediately** — save to `public/images/` and use the actual path in your components. Never use external URLs for production images
- **Attribution** — Unsplash and Pexels require attribution in some contexts. Include photographer credit in alt text or a credits section

## AI Image Generation (Gemini API)

Use the `/generate-image` skill to create custom images via Google's Gemini API directly. It checks the latest official docs for current model IDs, generates a script, runs it, and saves the image to your project. No community MCP servers needed.

When generating images:

### Prompting Best Practices

1. **Be specific in one sentence** — include style, mood, colors, composition:
   - Good: `"minimal SaaS dashboard UI mockup, dark theme, purple accent, clean data visualization"`
   - Bad: `"dashboard"`

2. **Name the style explicitly**:
   - `"editorial photography"` — magazine-quality, dramatic lighting
   - `"flat illustration"` — clean vector-like, modern SaaS
   - `"3D render"` — depth, materials, shadows
   - `"cinematic"` — film color grading, wide aspect ratio
   - `"Linear-style aesthetic"` — reference specific products for style

3. **Add "no text"** when you don't want rendered text in the image (text rendering is good but may not match your fonts)

4. **Specify aspect ratio in the prompt** — say "wide banner" or "vertical mobile" alongside any aspect ratio flags

5. **Use reference images for brand consistency** — pass existing brand assets as references to maintain visual coherence across generated images

### Common Image Sizes

| Use Case                 | Dimensions | Aspect Ratio | Notes                    |
| ------------------------ | ---------- | ------------ | ------------------------ |
| Hero banner (desktop)    | 1920x1080  | 16:9         | Full-width hero section  |
| Blog featured / OG image | 1200x630   | ~1.9:1       | Social media preview     |
| Square social            | 1080x1080  | 1:1          | Instagram, LinkedIn      |
| YouTube thumbnail        | 1280x720   | 16:9         | Video preview            |
| Twitter/X header         | 1500x500   | 3:1          | Wide banner              |
| Vertical story / mobile  | 1080x1920  | 9:16         | Instagram/TikTok stories |
| Team member photo        | 400x400    | 1:1          | Avatar / headshot        |
| Product screenshot       | 1200x900   | 4:3          | Feature showcase         |

### Transparent Assets

For icons, logos, or mascots that need transparency:

- Prompt with: `"[subject]. Place on a solid bright green background (#00FF00). The background must be a single flat green color with no gradients or shadows."`
- Process with FFmpeg or image tool to remove green background
- Save as PNG with alpha channel

### Output Directly to Project

Save generated images directly into the project's public directory:

- Next.js: `public/images/` → reference as `/images/filename.png`
- Astro/Vite: `public/images/` or `src/assets/`
- Name descriptively: `hero-landing.png`, `team-brainstorm.jpg`, not `image1.png`

## Image Optimization

Every image on the page should be optimized:

- **Format**: WebP for photos (80% quality), AVIF where supported, PNG only for transparency
- **Responsive `srcset`**: Provide 1x, 2x sizes minimum. Use `<picture>` for format fallbacks:
  ```html
  <picture>
    <source srcset="hero.avif" type="image/avif" />
    <source srcset="hero.webp" type="image/webp" />
    <img
      src="hero.jpg"
      alt="Description"
      width="1920"
      height="1080"
      loading="lazy"
    />
  </picture>
  ```
- **Explicit dimensions**: Always set `width` and `height` to prevent layout shift (CLS)
- **Lazy loading**: `loading="lazy"` on all below-fold images. Hero image should be `loading="eager"` or use `priority` in Next.js
- **Compression**: Target 80-85% quality for JPEG/WebP. Use Sharp, Squoosh, or image optimizer MCP if available

## Video

For hero background videos or product demos:

- **Stock video**: Pexels MCP supports video search — use for ambient backgrounds (tech, nature, abstract)
- **Format**: MP4 (H.264) for compatibility, WebM for smaller size. Provide both:
  ```html
  <video autoplay muted loop playsinline>
    <source src="hero-bg.webm" type="video/webm" />
    <source src="hero-bg.mp4" type="video/mp4" />
  </video>
  ```
- **Performance**: Keep under 5MB, 720p max for backgrounds, shorter is better (5-15 seconds loop)
- **Always `muted`** for autoplay (browsers block unmuted autoplay)
- **Poster image**: Set `poster="hero-poster.jpg"` for the first frame while loading
- **Fallback**: Show a static image for users with `prefers-reduced-motion`

## When Real Photos Aren't Available

If no stock photo MCP or image generator is available, at minimum:

- Use SVG illustrations (hand-drawn style, not clipart)
- Use CSS gradients and patterns as image placeholders
- Use Lottie animations for hero sections instead of static images
- Add clear `TODO` comments marking where real images should be placed
- **Never ship gray placeholder rectangles to production**
