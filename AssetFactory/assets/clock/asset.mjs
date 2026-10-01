import * as THREE from 'three';
import { Font } from '../../vendor/FontLoader.js';
import { buildGlyph } from './sculpted-type.mjs';
import { createSandpaper } from './sandpaper.mjs';
import { loadJSON } from '../../studio.mjs';

export async function createAsset({ renderer, reportProgress }) {
  const [fontData, config, presets] = await Promise.all([
    loadJSON(new URL('./font.json', import.meta.url)),
    loadJSON(new URL('./clock-config.json', import.meta.url)),
    loadJSON(new URL('./guide-recipes.json', import.meta.url)),
  ]);
  const font = new Font(fontData);
  const recipes = { ...presets.presets['latin-seeds'].glyphs, ...config.guides };
  recipes[':'] = { kind: 'paths', paths: [{ type: 'polyline', points: [[.5, -.1], [.5, 1.1]] }] };
  const applySandpaper = createSandpaper(renderer);
  const glyphs = {};
  for (const character of '0123456789:') {
    reportProgress(`Building ${character}…`);
    await new Promise(requestAnimationFrame);
    const glyph = buildGlyph(font, character, recipes[character], {
      height: config.height, condense: config.condense,
      heightMode: character === ':' ? 'cap' : 'uniform', spacing: .06, profile: config.profile,
    });
    if (character === ':') {
      const bounds = glyph.userData.bounds;
      const offset = config.height / 2 - bounds.low[1] - bounds.size[1] / 2;
      for (const mesh of glyph.children) mesh.geometry.translate(0, offset, 0);
      bounds.low[1] += offset;
    }
    applySandpaper(glyph);
    glyphs[character] = glyph;
  }
  const width = character => glyphs[character].userData.bounds.size[0];
  function row(group, text, y, scale = 1) {
    const characters = [...text], gap = .14;
    let x = -(characters.reduce((sum, c) => sum + width(c) * scale, 0) + gap * (characters.length - 1)) / 2;
    for (const character of characters) {
      const glyph = glyphs[character].clone(true);
      glyph.scale.setScalar(scale);
      glyph.position.set(x + width(character) * scale / 2, y, 0);
      group.add(glyph);
      x += width(character) * scale + gap;
    }
  }
  const fullSet = new THREE.Group();
  row(fullSet, '01234', 4.4);
  row(fullSet, '56789', 0);
  row(fullSet, ':', -2.6, .6);
  const stack = new THREE.Group();
  const advance = Math.max(...'0123456789'.split('').map(width)) + .14;
  for (const [index, character] of [...'1238'].entries()) {
    const glyph = glyphs[character].clone(true);
    glyph.scale.y = 1.15;
    glyph.position.set((index % 2 ? 1 : -1) * advance / 2,
      index < 2 ? config.height * 1.15 + .28 : 0, 0);
    stack.add(glyph);
  }
  const inline = new THREE.Group();
  row(inline, '12:38', 0);
  return {
    models: Object.entries(glyphs).map(([character, object]) => ({
      id: character === ':' ? 'colon' : `digit-${character}`, label: character, key: character, object,
    })),
    views: [
      { id: 'stacked', label: 'Clock · HH / MM', object: stack },
      { id: 'set', label: 'Full digit set', object: fullSet },
      { id: 'inline', label: 'Clock · HH:mm', object: inline },
    ],
    exportFrame: {
      pixels: [600, 900], center: [0, config.height / 2, 0],
      width: Math.max(...Object.keys(glyphs).map(width)), height: config.height, margin: .45,
    },
  };
}
