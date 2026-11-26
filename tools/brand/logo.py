#!/usr/bin/env python3
"""Brandhoop logo as SVG. Mark = a phone shaped like the letter B; wordmark outlined from Montserrat.

Library use:  from logo import mark_svg, lockup_v, lockup_h, icon_svg, PALETTE
Run directly: writes site/brand/logo/*.svg
"""
import math, pathlib
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
FONTS = ROOT / 'tools' / 'brand' / 'fonts'

PALETTE = {
    'navy': '#1F2744', 'navy2': '#2B3558', 'orange': '#D8662A', 'orange_dark': '#A9481C', 'orange_light': '#F08A45',
    'slate_light': '#8B94A0', 'slate': '#566170', 'slate_dark': '#2F3A45', 'paper': '#F6F6F6', 'ink': '#14182B'
}
P = PALETTE
_fonts = {}


def _font(weight):
    if weight not in _fonts:
        _fonts[weight] = TTFont(str(FONTS / f'montserrat-latin-{weight}-normal.woff'))
    return _fonts[weight]


def text_path(s, size, weight=800, tracking=0.0):
    """Returns (svg path d, width) for text outlined at origin baseline (0,0), x to the right."""
    f = _font(weight); gs = f.getGlyphSet(); cmap = f.getBestCmap(); upm = f['head'].unitsPerEm; k = size / upm
    x = 0.0; ds = []
    for ch in s:
        gname = cmap.get(ord(ch))
        if gname is None:
            x += size * 0.3; continue
        pen = SVGPathPen(gs)
        tp = TransformPen(pen, (k, 0, 0, -k, x, 0))
        gs[gname].draw(tp)
        ds.append(pen.getCommands())
        x += gs[gname].width * k + tracking * size
    return ' '.join(ds), x - tracking * size


def _fp_arcs(cx, cy, color, w=3.2):
    """A stylised fingerprint: nested arcs with gaps, plus a centre line."""
    out = []
    spec = [(9, 205, 335), (17, 190, 350), (25, 180, 360), (33, 172, 20), (41, 165, 30), (49, 160, 40)]
    for r, a0, a1 in spec:
        a0r, a1r = math.radians(a0), math.radians(a1)
        if a1 < a0: a1r += 2 * math.pi
        # draw the top arc and a shorter lower-left arc so it reads as a print, not a target
        x0, y0 = cx + r * math.cos(a0r), cy + r * math.sin(a0r)
        x1, y1 = cx + r * math.cos(a1r), cy + r * math.sin(a1r)
        large = 1 if (a1r - a0r) > math.pi else 0
        out.append(f'<path d="M{x0:.1f} {y0:.1f}A{r} {r} 0 {large} 1 {x1:.1f} {y1:.1f}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')
    out.append(f'<path d="M{cx} {cy-4}c0 10 -2 22 -7 34M{cx+6} {cy+2}c0 14 -3 26 -10 40" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>')
    return ''.join(out)



BODY_TRACED = "M408.0 154.6C405.5 154.9 402.7 155.3 400.0 155.8C397.3 156.4 394.7 157.0 392.0 157.9C389.3 158.8 386.7 159.8 384.0 161.0C381.3 162.3 378.7 163.6 376.0 165.3C373.4 167.0 370.6 168.9 368.1 171.0C365.6 173.2 363.0 175.6 360.9 178.1C358.7 180.6 356.9 183.4 355.2 186.0C353.6 188.6 352.2 191.3 351.0 194.0C349.9 196.7 348.9 199.3 348.3 202.0C347.6 204.7 347.4 207.3 347.2 210.0C347.0 212.7 347.0 215.3 347.0 218.0C347.0 220.7 347.0 223.3 347.0 226.0C347.0 228.7 347.0 231.3 347.0 234.0C347.0 236.7 347.0 239.3 347.0 242.0C347.0 244.7 347.0 247.3 347.0 250.0C347.0 252.7 347.0 255.3 347.0 258.0C347.0 260.7 347.0 263.3 347.0 266.0C347.0 268.7 347.0 271.3 347.0 274.0C347.0 276.7 347.0 279.3 347.0 282.0C347.0 284.7 347.0 287.3 347.0 290.0C347.0 292.7 347.0 295.3 347.0 298.0C347.0 300.7 347.0 303.3 347.0 306.0C347.0 308.7 347.0 311.3 347.0 314.0C347.0 316.7 347.0 319.3 347.0 322.0C347.0 324.7 347.0 327.3 347.0 330.0C347.0 332.7 347.0 335.3 347.0 338.0C347.0 340.7 347.0 343.3 347.0 346.0C347.0 348.7 347.0 351.3 347.0 354.0C347.0 356.7 347.0 359.3 347.0 362.0C347.0 364.7 347.0 367.3 347.0 370.0C347.0 372.7 347.0 375.3 347.0 378.0C347.0 380.7 347.0 383.3 347.0 386.0C347.0 388.7 347.0 391.3 347.0 394.0C347.0 396.7 347.0 399.3 347.0 402.0C347.0 404.7 347.0 407.3 347.0 410.0C347.0 412.7 347.0 415.3 347.0 418.0C347.0 420.7 347.0 423.3 347.0 426.0C347.0 428.7 347.0 431.3 347.0 434.0C347.0 436.7 347.0 439.3 347.0 442.0C347.0 444.7 347.0 447.3 347.0 450.0C347.0 452.7 347.0 455.3 347.0 458.0C347.0 460.7 347.0 463.3 347.0 466.0C347.0 468.7 347.0 471.3 347.0 474.0C347.0 476.7 347.0 479.3 347.0 482.0C347.0 484.7 347.0 487.3 347.0 490.0C347.0 492.7 347.0 495.3 347.0 498.0C347.0 500.7 347.0 503.3 347.0 506.0C347.0 508.7 347.0 511.3 347.0 514.0C347.0 516.7 347.0 519.3 347.0 522.0C347.0 524.7 347.0 527.3 347.0 530.0C347.0 532.7 347.0 535.3 347.0 538.0C347.0 540.7 347.0 543.3 347.0 546.0C347.0 548.7 347.0 551.3 347.0 554.0C347.0 556.7 347.0 559.3 347.0 562.0C347.0 564.7 347.0 567.3 347.0 570.0C347.0 572.7 347.0 575.3 347.0 578.0C347.1 580.7 347.1 583.3 347.3 586.0C347.5 588.7 347.9 591.3 348.4 594.0C348.9 596.7 349.6 599.3 350.4 602.0C351.1 604.7 352.1 607.3 353.1 610.0C354.1 612.7 355.2 615.3 356.5 618.0C357.8 620.7 359.2 623.3 360.9 626.0C362.5 628.7 364.3 631.4 366.4 634.0C368.5 636.6 370.8 639.4 373.2 641.9C375.7 644.4 378.4 646.9 381.0 649.1C383.6 651.3 386.3 653.3 389.0 655.1C391.7 656.9 394.3 658.4 397.0 659.9C399.7 661.3 402.3 662.5 405.0 663.7C407.7 664.8 410.3 665.8 413.0 666.6C415.7 667.5 418.3 668.3 421.0 668.9C423.7 669.6 426.3 670.2 429.0 670.6C431.7 671.1 434.3 671.4 437.0 671.7C439.7 671.9 442.3 671.9 445.0 672.0C447.7 672.0 450.3 672.0 453.0 672.0C455.7 672.0 458.3 672.0 461.0 672.0C463.7 672.0 466.3 672.0 469.0 672.0C471.7 672.0 474.3 672.0 477.0 672.0C479.7 672.0 482.3 672.0 485.0 672.0C487.7 672.0 490.3 672.0 493.0 672.0C495.7 672.0 498.3 672.0 501.0 672.0C503.7 672.0 506.3 672.0 509.0 672.0C511.7 672.0 514.3 672.0 517.0 672.0C519.7 672.0 522.3 672.0 525.0 672.0C527.7 672.0 530.3 672.0 533.0 672.0C535.7 671.9 538.3 671.9 541.0 671.8C543.7 671.6 546.3 671.3 549.0 671.0C551.7 670.7 554.3 670.4 557.0 670.0C559.7 669.6 562.3 669.2 565.0 668.7C567.7 668.2 570.3 667.6 573.0 667.0C575.7 666.4 578.3 665.8 581.0 665.1C583.7 664.4 586.3 663.7 589.0 663.0C591.7 662.2 594.3 661.4 597.0 660.5C599.7 659.6 602.3 658.6 605.0 657.5C607.7 656.5 610.3 655.3 613.0 654.1C615.7 652.9 618.3 651.6 621.0 650.2C623.7 648.8 626.3 647.4 629.0 645.8C631.7 644.3 634.3 642.6 637.0 640.9C639.7 639.1 642.3 637.2 645.0 635.2C647.7 633.2 650.4 631.1 653.0 628.9C655.6 626.6 658.3 624.2 660.8 621.7C663.3 619.3 665.7 616.6 668.0 614.0C670.3 611.4 672.4 608.7 674.4 606.0C676.3 603.3 678.2 600.7 679.9 598.0C681.6 595.3 683.3 592.7 684.8 590.0C686.3 587.3 687.8 584.7 689.0 582.0C690.3 579.3 691.4 576.7 692.4 574.0C693.5 571.3 694.4 568.7 695.3 566.0C696.2 563.3 697.0 560.7 697.7 558.0C698.5 555.3 699.1 552.7 699.7 550.0C700.3 547.3 700.8 544.7 701.3 542.0C701.7 539.3 702.1 536.7 702.5 534.0C702.8 531.3 703.2 528.7 703.4 526.0C703.6 523.3 703.8 520.7 703.9 518.0C703.9 515.3 703.9 512.7 703.8 510.0C703.6 507.3 703.4 504.7 703.1 502.0C702.9 499.3 702.6 496.7 702.2 494.0C701.8 491.3 701.4 488.7 700.9 486.0C700.4 483.3 699.9 480.7 699.2 478.0C698.6 475.3 697.9 472.7 697.1 470.0C696.3 467.3 695.4 464.7 694.4 462.0C693.4 459.3 692.2 456.7 691.0 454.0C689.8 451.3 688.5 448.7 687.1 446.0C685.6 443.3 684.1 440.7 682.4 438.0C680.8 435.3 679.0 432.7 677.1 430.0C675.2 427.3 673.1 424.6 670.9 422.0C668.7 419.4 666.3 416.8 663.8 414.3C661.3 411.9 658.6 409.6 656.0 407.4C653.4 405.2 650.6 403.2 648.0 401.3C645.5 399.3 642.4 397.6 640.6 395.8C638.9 393.9 637.3 392.0 637.4 390.1C637.5 388.1 639.5 386.2 641.5 384.2C643.4 382.2 646.4 380.2 649.0 378.0C651.5 375.9 654.2 373.7 656.6 371.3C659.1 368.9 661.6 366.4 663.9 363.9C666.2 361.3 668.4 358.6 670.4 356.0C672.5 353.3 674.4 350.7 676.1 348.0C677.8 345.3 679.4 342.7 680.9 340.0C682.3 337.3 683.6 334.7 684.8 332.0C686.0 329.3 687.1 326.7 688.0 324.0C689.0 321.3 689.9 318.7 690.7 316.0C691.5 313.3 692.2 310.7 692.8 308.0C693.5 305.3 694.1 302.7 694.6 300.0C695.1 297.3 695.5 294.7 695.8 292.0C696.2 289.3 696.5 286.7 696.6 284.0C696.8 281.3 696.9 278.7 696.9 276.0C696.9 273.3 696.9 270.7 696.7 268.0C696.5 265.3 696.3 262.7 696.0 260.0C695.6 257.3 695.3 254.7 694.8 252.0C694.4 249.3 693.9 246.7 693.2 244.0C692.6 241.3 691.9 238.7 691.1 236.0C690.3 233.3 689.4 230.7 688.4 228.0C687.4 225.3 686.3 222.7 685.0 220.0C683.8 217.3 682.4 214.7 680.9 212.0C679.4 209.3 677.7 206.7 675.9 204.0C674.0 201.3 672.1 198.6 669.9 196.0C667.7 193.4 665.3 190.6 662.8 188.1C660.3 185.6 657.6 183.1 655.0 180.9C652.4 178.6 649.7 176.6 647.0 174.7C644.3 172.9 641.7 171.3 639.0 169.7C636.3 168.2 633.7 166.9 631.0 165.7C628.3 164.4 625.7 163.3 623.0 162.3C620.3 161.3 617.7 160.4 615.0 159.6C612.3 158.8 609.7 158.1 607.0 157.5C604.3 156.9 601.7 156.4 599.0 156.0C596.3 155.5 593.7 155.2 591.0 154.9C588.3 154.6 585.7 154.4 583.0 154.2C580.3 154.1 577.7 154.1 575.0 154.0C572.3 154.0 569.7 154.0 567.0 154.0C564.3 154.0 561.7 154.0 559.0 154.0C556.3 154.0 553.7 154.0 551.0 154.0C548.3 154.0 545.7 154.0 543.0 154.0C540.3 154.0 537.7 154.0 535.0 154.0C532.3 154.0 529.7 154.0 527.0 154.0C524.3 154.0 521.7 154.0 519.0 154.0C516.3 154.0 513.7 154.0 511.0 154.0C508.3 154.0 505.7 154.0 503.0 154.0C500.3 154.0 497.7 154.0 495.0 154.0C492.3 154.0 489.7 154.0 487.0 154.0C484.3 154.0 481.7 154.0 479.0 154.0C476.3 154.0 473.7 154.0 471.0 154.0C468.3 154.0 465.7 154.0 463.0 154.0C460.3 154.0 457.7 154.0 455.0 154.0C452.3 154.0 449.7 154.0 447.0 154.0C444.3 154.0 441.7 154.0 439.0 154.0C436.3 154.0 433.7 154.0 431.0 154.0C428.3 154.0 425.7 154.0 423.0 154.0C420.3 154.0 417.5 154.0 415.0 154.1C412.5 154.2 410.5 154.3 408.0 154.6Z"
LOWER_NEW = 'M349 520C349 452 405 394 478 391L640 391L730 391L730 700L330 700L330 520Z'
LOWER_EDGE = 'M349 525C349 455 405 396 480 391L626 391'


def _rng(seed):
    x = seed
    while True:
        x = (x * 1103515245 + 12345) % 2147483648
        yield x / 2147483648


def _fp_real(cx, cy, uid):
    """A believable fingerprint: nested loop ridges with gaps, a whorl core, slanted ridges at the base."""
    r = _rng(7)
    out = []
    ridge = '#E9945A'
    def stroke(d, w=2.5, op=.95, dash=None):
        da = ''
        if dash:
            da = ' stroke-dasharray="%s"' % dash
        out.append(f'<path d="{d}" fill="none" stroke="{ridge}" stroke-width="{w}" stroke-linecap="round" opacity="{op}"{da}/>')
    ox, oy = cx + 2, cy - 4
    # core: tight upside-down U
    stroke(f'M{ox-3.5} {oy+30}V{oy+4}A3.5 4.5 0 0 1 {ox+3.5} {oy+4}V{oy+30}', 2.4)
    for k in range(1, 11):
        w = 4.0 + k * 5.6; t = 5.0 + k * 6.0
        bend = k * 0.9
        d = (f'M{ox-w:.1f} {oy+46+bend:.1f}C{ox-w-1:.1f} {oy+20:.1f} {ox-w:.1f} {oy+4:.1f} {ox-w:.1f} {oy:.1f}'
             f'A{w:.1f} {t:.1f} 0 0 1 {ox+w:.1f} {oy:.1f}'
             f'C{ox+w:.1f} {oy+8:.1f} {ox+w+1.5:.1f} {oy+22:.1f} {ox+w+bend*0.8:.1f} {oy+46+bend:.1f}')
        dash = None
        if k in (3, 6, 8, 10):
            a = 14 + (k * 7) % 17; dash = f'{a} 2.5 {a+9} 3'
        stroke(d, 2.4, .92, dash)
    return ''.join(out)


def _real_defs(uid):
    u = uid
    return (f'<defs>'
        f'<linearGradient id="{u}b" x1="0" y1="0" x2="0.35" y2="1"><stop offset="0" stop-color="#5E6874"/><stop offset=".5" stop-color="#434B58"/><stop offset="1" stop-color="#2B323E"/></linearGradient>'
        f'<radialGradient id="{u}hi" cx="690" cy="215" r="290" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#A7B0B8"/><stop offset=".45" stop-color="#7C8791" stop-opacity=".75"/><stop offset="1" stop-color="#4A545D" stop-opacity="0"/></radialGradient>'
        f'<linearGradient id="{u}lo" x1="0" y1="0" x2="1" y2="0.55"><stop offset="0" stop-color="#262D3A"/><stop offset=".55" stop-color="#3C4450"/><stop offset="1" stop-color="#4B535D"/></linearGradient>'
        f'<linearGradient id="{u}lo2" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".10"/><stop offset=".25" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".22"/></linearGradient>'
        f'<linearGradient id="{u}rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#D5D8DC"/><stop offset=".35" stop-color="#8E959D"/><stop offset=".7" stop-color="#6C737C"/><stop offset="1" stop-color="#B2B7BD"/></linearGradient>'
        f'<linearGradient id="{u}or" gradientUnits="userSpaceOnUse" x1="0" y1="245" x2="0" y2="330"><stop offset="0" stop-color="#F0894A"/><stop offset="1" stop-color="#C45A22"/></linearGradient>'
        f'<radialGradient id="{u}fp" cx=".45" cy=".4" r=".75"><stop offset="0" stop-color="#B85F2A"/><stop offset=".7" stop-color="#A24C1E"/><stop offset="1" stop-color="#7E3411"/></radialGradient>'
        f'<linearGradient id="{u}ring" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5A2A12"/><stop offset=".5" stop-color="#B8683A"/><stop offset="1" stop-color="#E2A06F"/></linearGradient>'
        f'<linearGradient id="{u}pill" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#171B24"/><stop offset="1" stop-color="#2E3440"/></linearGradient>'
        f'<linearGradient id="{u}btn" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5E616D"/><stop offset=".6" stop-color="#9A9CA8"/><stop offset="1" stop-color="#6E717C"/></linearGradient>'
        f'<clipPath id="{u}cb"><path d="{BODY_TRACED}"/></clipPath>'
        f'<clipPath id="{u}cf"><circle cx="523" cy="518" r="64"/></clipPath>'
        f'<filter id="{u}bl2" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2"/></filter>'
        f'<filter id="{u}bl4" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="5"/></filter>'
        f'<filter id="{u}bl8" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="10"/></filter>'
        f'</defs>')


def _real_inner(uid):
    u = uid
    PLUG = ('M464 249H500C524 249 540 266 540 286.5C540 307 524 324 500 324H464Z', 'M450 250V324', 'M408 276H446M408 288H446M408 300H446')
    g = []
    # side buttons (behind body)
    for y0, y1 in ((243, 293), (298, 336), (353, 391), (402, 451)):
        g.append(f'<rect x="331" y="{y0}" width="17" height="{y1-y0}" rx="7" fill="url(#{u}btn)" stroke="#40434D" stroke-width="1.5"/>')
    g.append(f'<path d="{BODY_TRACED}" fill="url(#{u}b)"/>')
    g.append(f'<g clip-path="url(#{u}cb)">')
    g.append(f'<rect x="322" y="144" width="420" height="300" fill="url(#{u}hi)"/>')
    # lower bowl: shadow cast on the upper body, then the bowl itself
    g.append(f'<path d="{LOWER_EDGE}" fill="none" stroke="#10141B" stroke-width="16" opacity=".45" filter="url(#{u}bl8)" transform="translate(0,-6)"/>')
    g.append(f'<path d="{LOWER_NEW}" fill="url(#{u}lo)"/><path d="{LOWER_NEW}" fill="url(#{u}lo2)"/>')
    g.append(f'<path d="{LOWER_EDGE}" fill="none" stroke="#8791A0" stroke-width="3" opacity=".5" filter="url(#{u}bl2)" transform="translate(0,1.5)"/>')
    g.append('</g>')
    # rim: metal edge + soft inner line
    g.append(f'<path d="{BODY_TRACED}" fill="none" stroke="url(#{u}rim)" stroke-width="5.5"/>')
    g.append(f'<path d="{BODY_TRACED}" fill="none" stroke="#161A22" stroke-width="2" opacity=".55" transform="translate(0,0)" clip-path="url(#{u}cb)"/>')
    # camera pill
    g.append(f'<rect x="460" y="181" width="110" height="31" rx="15.5" fill="url(#{u}pill)" stroke="#0F131A" stroke-width="1.5"/>'
             f'<rect x="466" y="184" width="98" height="3" rx="1.5" fill="#fff" opacity=".07"/>'
             f'<circle cx="552" cy="196.5" r="7" fill="#1A2030" stroke="#3A4258" stroke-width="1.5"/><circle cx="552" cy="196.5" r="3.2" fill="#2F3C66"/><circle cx="550.8" cy="195.2" r="1.1" fill="#fff" opacity=".7"/>')
    # engraved charger: a D-shaped plug body with a slot, two prongs, and an "eye" looking up and to the right
    DP = 'M447 256H504.5A32.5 32.5 0 0 1 504.5 321H447Z'
    BAR = 'M461.6 256V321'
    PRONG = 'M412 278H447M412 300H447'
    g.append(f'<path d="{DP}" fill="#0E1218" stroke="#0E1218" stroke-width="15" stroke-linejoin="round" opacity=".55" filter="url(#{u}bl2)" transform="translate(0,2.5)"/>')
    g.append(f'<path d="{PRONG}" stroke="#0E1218" stroke-width="13" stroke-linecap="round" opacity=".55" filter="url(#{u}bl2)" transform="translate(0,2.5)"/>')
    g.append(f'<path d="{DP}" fill="#252A34"/><path d="{DP}" fill="none" stroke="#10141B" stroke-width="3" opacity=".6" transform="translate(0,3)" clip-path="url(#{u}cb)"/>')
    for d, w in ((PRONG, 7), (DP, 6.2), (BAR, 5)):
        g.append(f'<path d="{d}" fill="none" stroke="#5A2610" stroke-width="{w+2.2}" stroke-linecap="round" stroke-linejoin="round" opacity=".85"/>')
    for d, w in ((PRONG, 7), (DP, 6.2), (BAR, 5)):
        g.append(f'<path d="{d}" fill="none" stroke="url(#{u}or)" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
        g.append(f'<path d="{d}" fill="none" stroke="#F7B27D" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" opacity=".4" transform="translate(0,-1.9)"/>')
    g.append(f'<circle cx="510.6" cy="286" r="15.6" fill="#5A2610" opacity=".85"/><circle cx="510.6" cy="286" r="14.2" fill="url(#{u}or)"/>'
             f'<circle cx="515.2" cy="282.4" r="5.4" fill="#C86A30"/><circle cx="515.2" cy="282.4" r="4.2" fill="#2A2D36"/>')
    # engraved dot
    g.append(f'<circle cx="584" cy="286" r="17.5" fill="#0E1218" opacity=".6" filter="url(#{u}bl2)" transform="translate(0,2.5)"/><circle cx="584" cy="286" r="15.6" fill="#262B34"/>'
             f'<circle cx="584" cy="286.8" r="13.6" fill="url(#{u}or)"/><path d="M570.6 284A13.6 13.6 0 0 1 597.4 284" fill="none" stroke="#000" stroke-width="3" opacity=".25"/>')
    # fingerprint well
    g.append(f'<circle cx="523" cy="518" r="72" fill="#0B0F15" opacity=".55" filter="url(#{u}bl4)" transform="translate(0,5)"/>'
             f'<circle cx="523" cy="518" r="69" fill="url(#{u}ring)"/><circle cx="523" cy="518" r="64.5" fill="url(#{u}fp)"/>'
             f'<g clip-path="url(#{u}cf)"><g transform="rotate(-10 523 518)">{_fp_real(523, 518, u)}</g>'
             f'<circle cx="523" cy="518" r="70" fill="none" stroke="#000" stroke-width="16" opacity=".38" filter="url(#{u}bl4)" transform="translate(0,6)"/></g>')
    return ''.join(g)


def mark_defs(uid='m'):
    return _real_defs(uid)

def _old_mark_defs(uid='m'):
    return (f'<defs>'
            f'<linearGradient id="{uid}body" x1="0.85" y1="0.05" x2="0.1" y2="0.95"><stop offset="0" stop-color="{P["slate_light"]}"/><stop offset=".45" stop-color="{P["slate"]}"/><stop offset="1" stop-color="{P["slate_dark"]}"/></linearGradient>'
            f'<linearGradient id="{uid}low" x1="0.2" y1="0" x2="0.8" y2="1"><stop offset="0" stop-color="#3A4655"/><stop offset="1" stop-color="#27313C"/></linearGradient>'
            f'<radialGradient id="{uid}fp" cx=".42" cy=".38" r=".75"><stop offset="0" stop-color="{P["orange_light"]}"/><stop offset=".6" stop-color="{P["orange"]}"/><stop offset="1" stop-color="{P["orange_dark"]}"/></radialGradient>'
            f'<linearGradient id="{uid}shine" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity=".28"/><stop offset=".25" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            f'</defs>')


BODY = BODY_TRACED
LOWER = 'M378 478C378 424 430 394 500 394L618 394C676 402 706 448 706 508C706 590 662 640 584 640L410 640C392 640 378 630 378 612Z'


def mark_inner(style='color', uid='m', body_color=None, detail_color=None):
    """The B-phone in original logo coordinates (x 330..720, y 150..680)."""
    if style == 'color':
        return _real_inner(uid)
    if style == 'color':
        body, low, accent, accent2, dark, bez = f'url(#{uid}body)', f'url(#{uid}low)', P['orange'], P['orange'], '#262B36', '#B9C0C9'
        fp_fill = f'url(#{uid}fp)'; fp_line = '#8F3F17'
    else:  # solid: body in one colour, details knocked out in detail_color
        bc = body_color or P['navy']; dc = detail_color or '#FFFFFF'
        body, low, accent, accent2, dark, bez = bc, bc, dc, dc, dc, dc
        fp_fill = dc; fp_line = bc
    g = [f'<path d="{BODY}" fill="{body}"/>']
    if style == 'color':
        g.append(f'<path d="{LOWER}" fill="{low}" opacity=".62"/>')
        g.append(f'<path d="{BODY}" fill="url(#{uid}shine)"/>')
        g.append(f'<path d="{BODY}" fill="none" stroke="{bez}" stroke-width="6" stroke-opacity=".75"/>')
    # side buttons
    btn = '#7F8791' if style == 'color' else (detail_color or '#FFFFFF')
    g.append(f'<rect x="330" y="238" width="17" height="62" rx="6" fill="{btn}"/><rect x="330" y="352" width="17" height="62" rx="6" fill="{btn}"/>')
    # notch + lens
    g.append(f'<rect x="461" y="181" width="108" height="32" rx="16" fill="{dark}"/>')
    if style == 'color': g.append('<circle cx="551" cy="197" r="5.5" fill="#3B4560"/>')
    # plug icon
    g.append(f'<g fill="none" stroke="{accent}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round">'
             f'<path d="M458 252H498C522 252 540 268 540 289C540 310 522 326 498 326H458Z"/>'
             f'<path d="M412 272H440M408 306H440M440 272V306"/></g>')
    g.append(f'<circle cx="508" cy="289" r="12" fill="none" stroke="{accent}" stroke-width="5"/><circle cx="510" cy="288" r="4" fill="{accent}"/>')
    g.append(f'<circle cx="580" cy="288" r="12" fill="{accent2}"/>')
    # fingerprint disc
    g.append(f'<circle cx="523" cy="518" r="72" fill="{fp_fill}"/>')
    if style == 'color':
        g.append(f'<circle cx="523" cy="518" r="72" fill="none" stroke="{P["orange_dark"]}" stroke-width="5"/><circle cx="523" cy="518" r="62" fill="none" stroke="{P["orange_light"]}" stroke-opacity=".55" stroke-width="2.5"/>')
    g.append(_fp_arcs(523, 518, fp_line))
    return ''.join(g)


def mark_svg(style='color', body_color=None, detail_color=None, uid='m', size=None):
    s = f' width="{size[0]}" height="{size[1]}"' if size else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="322 144 398 536"{s} role="img" aria-label="Brandhoop mark">'
            f'{mark_defs(uid) if style == "color" else ""}{mark_inner(style, uid, body_color, detail_color)}</svg>')


def wordmark(brand_color=None, hoop_color=None, sub_color=None, cx=0, y=0, size=100, sub_size=0.62):
    """BRANDHOOP + MOBILE POINT, centred on cx; returns (svg group, width). Baseline of line 1 at y."""
    brand_color = brand_color or P['navy']; hoop_color = hoop_color or P['orange']; sub_color = sub_color or '#C16D41'
    d1, w1 = text_path('BRAND', size, 800, 0.0); d2, w2 = text_path('HOOP', size, 800, 0.0)
    total = w1 + w2; x0 = cx - total / 2
    sub_fs = size * sub_size; d3, w3 = text_path('MOBILE POINT', sub_fs, 600, 0.04)
    g = (f'<path d="{d1}" transform="translate({x0:.1f} {y})" fill="{brand_color}"/>'
         f'<path d="{d2}" transform="translate({x0 + w1:.1f} {y})" fill="{hoop_color}"/>'
         f'<path d="{d3}" transform="translate({cx - w3 / 2:.1f} {y + size * 0.95:.1f})" fill="{sub_color}"/>')
    return g, total


def lockup_v(style='color', mode='light', uid='v'):
    """Mark above wordmark. mode light: navy/orange text; dark: white/orange text; mono: one colour."""
    if mode == 'dark': bc, hc, sc = '#FFFFFF', P['orange_light'], P['orange_light']
    elif mode == 'mono': bc = hc = sc = P['navy']
    elif mode == 'white': bc = hc = sc = '#FFFFFF'
    else: bc, hc, sc = '#242B45', P['orange'], '#C16D41'
    mark_kw = {}
    if mode == 'mono': mark_kw = dict(style='solid', body_color=P['navy'], detail_color='#FFFFFF')
    elif mode == 'white': mark_kw = dict(style='solid', body_color='#FFFFFF', detail_color=P['navy'])
    else: mark_kw = dict(style=style)
    wm, w = wordmark(bc, hc, sc, cx=521, y=800, size=102)
    inner = mark_inner(uid=uid, **mark_kw)
    defs = mark_defs(uid) if mark_kw['style'] == 'color' else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="150 130 742 800" role="img" aria-label="Brandhoop Mobile Point">{defs}{inner}{wm}</svg>')


def lockup_h(mode='light', uid='h'):
    """Mark on the left, two text lines on the right."""
    if mode == 'dark': bc, hc, sc = '#FFFFFF', P['orange_light'], P['orange_light']
    elif mode == 'mono': bc = hc = sc = P['navy']
    elif mode == 'white': bc = hc = sc = '#FFFFFF'
    else: bc, hc, sc = '#242B45', P['orange'], '#C16D41'
    if mode == 'mono': mk = dict(style='solid', body_color=P['navy'], detail_color='#FFFFFF')
    elif mode == 'white': mk = dict(style='solid', body_color='#FFFFFF', detail_color=P['navy'])
    else: mk = dict(style='color')
    d1, w1 = text_path('BRAND', 112, 800); d2, w2 = text_path('HOOP', 112, 800); d3, w3 = text_path('MOBILE POINT', 70, 600, 0.045)
    tx = 760; ty = 438
    defs = mark_defs(uid) if mk['style'] == 'color' else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="322 144 {tx - 322 + w1 + w2 + 20} 536" role="img" aria-label="Brandhoop Mobile Point">{defs}{mark_inner(uid=uid, **mk)}'
            f'<path d="{d1}" transform="translate({tx} {ty})" fill="{bc}"/><path d="{d2}" transform="translate({tx + w1:.1f} {ty})" fill="{hc}"/>'
            f'<path d="{d3}" transform="translate({tx + 4} {ty + 92})" fill="{sc}"/></svg>')


def icon_svg(variant='light', rounded=True, uid='i'):
    """Square app icon 1024: the mark centred on a plain tile."""
    bg = '#F6F6F6' if variant == 'light' else P['navy']
    rx = 224 if rounded else 0
    if variant == 'light':
        inner = mark_inner('color', uid); defs = mark_defs(uid)
    else:  # on navy: the mark in white with orange details would lose the slate body, so use the colour mark on a lighter navy tile
        inner = mark_inner('color', uid); defs = mark_defs(uid)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-label="Brandhoop"><rect width="1024" height="1024" rx="{rx}" fill="{bg}"/>'
            f'{defs}<g transform="translate(512 512) scale(1.02) translate(-521 -412)">{inner}</g></svg>')


def write_all(out):
    out = pathlib.Path(out); out.mkdir(parents=True, exist_ok=True)
    files = {
        'brandhoop-logo.svg': lockup_v('color', 'light', 'a'),
        'brandhoop-logo-on-dark.svg': lockup_v('color', 'dark', 'b'),
        'brandhoop-logo-mono-navy.svg': lockup_v('color', 'mono', 'c'),
        'brandhoop-logo-white.svg': lockup_v('color', 'white', 'd'),
        'brandhoop-logo-horizontal.svg': lockup_h('light', 'e'),
        'brandhoop-logo-horizontal-on-dark.svg': lockup_h('dark', 'f'),
        'brandhoop-logo-horizontal-mono.svg': lockup_h('mono', 'g'),
        'brandhoop-mark.svg': mark_svg('color', uid='h1'),
        'brandhoop-mark-mono-navy.svg': mark_svg('solid', P['navy'], '#FFFFFF'),
        'brandhoop-mark-white.svg': mark_svg('solid', '#FFFFFF', P['navy']),
        'brandhoop-mark-orange.svg': mark_svg('solid', P['orange'], '#FFFFFF'),
        'brandhoop-icon.svg': icon_svg('light', True, 'j'),
        'brandhoop-icon-square.svg': icon_svg('light', False, 'k'),
    }
    # the wordmark alone
    wm, w = wordmark(cx=0, y=0, size=100)
    files['brandhoop-wordmark.svg'] = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{-w/2 - 20:.0f} -90 {w + 40:.0f} 170" role="img" aria-label="Brandhoop Mobile Point">{wm}</svg>'
    for n, s in files.items():
        (out / n).write_text(s, encoding='utf-8')
    return sorted(files)


if __name__ == '__main__':
    print(write_all(ROOT / 'site' / 'brand' / 'logo'))
