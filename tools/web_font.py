"""Bake the UI TTF into FTE's proportional Kex font format for web builds."""
import io
import math


def bake_font(source: bytes) -> dict[str, bytes]:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError as error:
        raise RuntimeError('Web font baking requires Pillow: python -m pip install Pillow') from error
    font = ImageFont.truetype(io.BytesIO(source), 40)
    ascent, descent = font.getmetrics()
    line_height = ascent + descent
    row_height = line_height + 8
    atlas = Image.new('RGBA', (2048, 2048))
    lines = ['texture "gfx/web-font.tga"']
    codepoints = [*range(32, 127), *range(160, 384), *range(1024, 1280),
                  *range(0x2010, 0x203b), 0x20ac, 0x2122]
    x = y = 0
    for codepoint in codepoints:
        glyph = chr(codepoint)
        width = math.ceil((font.getlength(glyph) + 4) / 2) * 2
        if x + width > atlas.width:
            x = 0
            y += row_height
        if y + row_height > atlas.height:
            raise ValueError('Web font atlas is full')
        cell = Image.new('RGBA', (line_height, line_height))
        ImageDraw.Draw(cell).text((2, ascent), glyph, font=font,
                                 anchor='ls', fill=(255, 255, 255, 255))
        cell = cell.resize((width, line_height), Image.Resampling.LANCZOS)
        atlas.alpha_composite(cell, (x, y + 2))
        # FTE removes two pixels at the top and bottom of non-space Kex glyphs.
        height = line_height if codepoint == 32 else line_height + 4
        lines.append(f'{codepoint} {x} {y} {width} {height} 0')
        x += width + 2
    output = io.BytesIO()
    alpha = atlas.getchannel('A')
    atlas = Image.merge('RGBA', (alpha, alpha, alpha, alpha))
    atlas.save(output, format='TGA', compression='tga_rle')
    return {'fonts/gfx/font.kfont': ('\n'.join(lines) + '\n').encode(),
            'gfx/web-font.tga': output.getvalue()}
