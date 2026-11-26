#!/usr/bin/env python3
"""Writes site/brand/index.html: the brand kit page (logos, colours, print and social files)."""
import pathlib, html
ROOT = pathlib.Path(__file__).resolve().parents[2]
B = ROOT / 'site' / 'brand'

LOGOS = [('Logo', 'brandhoop-logo', 'light'), ('Logo on dark', 'brandhoop-logo-on-dark', 'dark'), ('Horizontal', 'brandhoop-logo-horizontal', 'light'),
         ('Horizontal on dark', 'brandhoop-logo-horizontal-on-dark', 'dark'), ('One colour (navy)', 'brandhoop-logo-mono-navy', 'light'), ('White', 'brandhoop-logo-white', 'dark'),
         ('Mark', 'brandhoop-mark', 'light'), ('Mark, orange', 'brandhoop-mark-orange', 'light'), ('Mark, white', 'brandhoop-mark-white', 'dark'), ('Wordmark', 'brandhoop-wordmark', 'light'), ('App icon', 'brandhoop-icon', 'light')]
PRINT = [('Business card, front', 'business-card-front.png', ''), ('Business card, back', 'business-card-back.png', ''), ('A4 poster', 'poster-a4.png', 'poster-a4.pdf'),
         ('WhatsApp status', 'whatsapp-status.png', ''), ('Instagram post', 'instagram-post.png', ''), ('Profile picture', 'profile-picture.png', ''), ('Facebook cover', 'facebook-cover.png', ''),
         ('Google profile cover', 'google-profile-cover.png', ''), ('Shop board 3:1', 'shop-board-3x1.png', 'shop-board-3x1.pdf'), ('Letterhead A4', 'letterhead-a4.png', 'letterhead-a4.pdf'),
         ('Counter card A5', 'counter-card-a5.png', 'counter-card-a5.pdf')] + [(f'Highlight: {n}', f'highlight-{n.lower().replace(" ", "-")}.png', '') for n in ['Phones', 'Accessories', 'Skin cutting', 'Repair', 'EMI', 'Shop tour', 'Customers']]
COLORS = [('Navy', '#1F2744'), ('Navy 2', '#2B3558'), ('Slate', '#566170'), ('Slate light', '#8B94A0'), ('Orange', '#D8662A'), ('Orange light', '#F08A45'), ('Orange dark', '#A9481C'), ('Paper', '#F6F6F6')]

def esc(s): return html.escape(s)
cards = ''.join(f'<figure class="lg {m}"><img src="logo/{f}.svg" alt="{esc(n)}" loading="lazy"><figcaption><b>{esc(n)}</b><span><a href="logo/{f}.svg" download>SVG</a>' + (f' · <a href="logo/{f}.png" download>PNG</a>' if (B / 'logo' / f'{f}.png').exists() else '') + '</span></figcaption></figure>' for n, f, m in LOGOS)
pr = ''.join(f'<figure class="pr"><img src="print/{p}" alt="{esc(n)}" loading="lazy"><figcaption><b>{esc(n)}</b><span><a href="print/{p}" download>PNG</a>' + (f' · <a href="print/{pdf}">PDF</a>' if pdf else '') + '</span></figcaption></figure>' for n, p, pdf in PRINT)
cols = ''.join(f'<div class="sw"><i style="background:{c}"></i><b>{esc(n)}</b><code>{c}</code></div>' for n, c in COLORS)
doc = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Brand kit · Brandhoop Mobile Point</title><meta name="robots" content="noindex">
<link rel="icon" type="image/png" href="../favicon.png">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Montserrat:wght@500;600;700;800&family=Noto+Sans+Devanagari:wght@500;700&display=swap">
<style>
:root {{ --navy:#1F2744; --orange:#D8662A; --ink:#14182B; --muted:#566170; --paper:#F6F6F6; --card:#fff; --line:#E1E4EA; }}
@media (prefers-color-scheme: dark) {{ :root {{ --ink:#ECEEF6; --muted:#A4ABBD; --paper:#0F1322; --card:#181D33; --line:#2A3050; --navy:#C9D0EE; }} }}
* {{ box-sizing:border-box; }} body {{ margin:0; font:16px/1.55 Montserrat,"Noto Sans Devanagari",system-ui,sans-serif; background:var(--paper); color:var(--ink); }}
.wrap {{ max-width:1100px; margin:0 auto; padding:24px 20px 70px; }} h1 {{ font-size:clamp(28px,5vw,40px); margin:10px 0 4px; color:var(--navy); }} h2 {{ margin:38px 0 10px; font-size:22px; color:var(--navy); }}
p {{ color:var(--muted); max-width:70ch; }} a {{ color:var(--orange); font-weight:700; }}
.grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(250px,1fr)); gap:14px; }}
figure {{ margin:0; background:var(--card); border:1px solid var(--line); border-radius:16px; overflow:hidden; }}
figure.lg img {{ display:block; width:100%; height:190px; object-fit:contain; padding:18px; background:#F6F6F6; }} figure.lg.dark img {{ background:#1F2744; }}
figure.pr img {{ display:block; width:100%; height:230px; object-fit:contain; background:#E8EAF0; }}
figcaption {{ padding:10px 14px 12px; display:flex; justify-content:space-between; gap:8px; font-size:14px; }} figcaption span {{ white-space:nowrap; }}
.sw {{ display:flex; flex-direction:column; gap:3px; }} .sw i {{ height:64px; border-radius:12px; border:1px solid var(--line); }} .sw code {{ color:var(--muted); font-size:13px; }}
.rules li {{ margin:6px 0; color:var(--muted); }} a.back {{ font-size:14px; }}
</style></head><body><div class="wrap">
<a class="back" href="../">← Back to the website</a>
<h1>Brandhoop brand kit</h1>
<p>The logo is a phone shaped like the letter B. Every file here is made from the same vector artwork, so it stays sharp at any size. SVG files scale without limit; PNG files have a transparent background.</p>
<p><a href="cards/" style="display:inline-block;background:var(--orange);color:#fff;padding:10px 16px;border-radius:12px;text-decoration:none">Open Card Studio: 20 customizable card styles + image prompts →</a></p>
<h2>Logos</h2><div class="grid">{cards}</div>
<h2>Colours</h2><div class="grid" style="grid-template-columns:repeat(auto-fill,minmax(130px,1fr))">{cols}</div>
<p style="margin-top:12px">Type: Montserrat for names and headings, Noto Sans Devanagari for Hindi.</p>
<h2>Print and social files</h2><div class="grid">{pr}</div>
<h2>Using the logo</h2><ul class="rules"><li>Use the full-colour logo on light grey or white, the “on dark” logo on navy or photos with a dark overlay.</li><li>Use the one-colour or white version when printing in a single colour, on stamps, or on bills.</li><li>Leave clear space around the logo at least the height of the “B” bowl. Do not stretch, recolour or add shadows.</li><li>The business card, poster, board and letterhead carry the shop address and phone. If the address or phone changes, ask Claude to regenerate them, or use the Design Studio in the admin panel.</li></ul>
</div></body></html>'''
(B / 'index.html').write_text(doc, encoding='utf-8')
print('brand page ok')
