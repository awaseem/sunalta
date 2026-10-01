import * as THREE from 'three';
import { OrbitControls } from './vendor/OrbitControls.js';
import { GLTFExporter } from './vendor/GLTFExporter.js';
import { createStudio, disposeAsset, frameCamera, geometryStats, loadJSON, objectBounds } from './studio.mjs';

const stage = document.querySelector('#stage');
const status = document.querySelector('#status');
const assetSelect = document.querySelector('#asset'), viewSelect = document.querySelector('#view');
const exportButton = document.querySelector('#export');
const query = new URLSearchParams(location.search);
let renderer, scene, camera, controls, asset, entries = [], catalog = [], preview;
let loading = false, exporting = false;

function reportProgress(message, error = false) {
  status.textContent = message;
  status.dataset.error = String(error);
}

function setBusy(busy) {
  document.querySelector('#reload').disabled = busy;
  document.querySelector('#background').disabled = busy;
  assetSelect.disabled = busy || catalog.length === 0;
  for (const element of [viewSelect, exportButton, document.querySelector('#angle'), document.querySelector('#reset')]) {
    element.disabled = busy || !asset;
  }
  if (controls) controls.enabled = !busy;
}

function updateURL() {
  const parameters = new URLSearchParams({ asset: assetSelect.value, view: viewSelect.value });
  history.replaceState(null, '', `?${parameters}`);
}

function render() { if (renderer && !exporting) renderer.render(scene, camera); }

function resize() {
  if (!renderer || exporting) return;
  const width = stage.clientWidth, height = stage.clientHeight;
  if (!width || !height) return;
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.setSize(width, height, false);
  if (preview) frameCamera(camera, preview, width / height, controls.target);
  render();
}

function resetCamera(angled = false) {
  if (!preview) return;
  const bounds = objectBounds(preview), center = bounds.getCenter(new THREE.Vector3());
  const distance = Math.max(20, bounds.getSize(new THREE.Vector3()).length() * 3);
  controls.target.copy(center);
  camera.position.copy(center).add(new THREE.Vector3(angled ? .36 : 0, angled ? .13 : 0, 1).normalize().multiplyScalar(distance));
  camera.near = .01;
  camera.far = distance * 4;
  camera.zoom = 1;
  camera.up.set(0, 1, 0);
  camera.lookAt(center);
  controls.update();
  resize();
}

function showView(id) {
  const entry = entries.find(item => item.id === id) ?? entries[0];
  if (!entry) return;
  if (preview) scene.remove(preview);
  preview = entry.object.clone(true);
  scene.add(preview);
  viewSelect.value = entry.id;
  const stats = geometryStats(preview);
  document.querySelector('#stats').textContent = `${stats.triangles.toLocaleString()} triangles · ${stats.vertices.toLocaleString()} vertices`;
  updateURL();
  resetCamera();
}

function validateAsset(value) {
  if (!Array.isArray(value?.models) || value.models.length === 0) throw new Error('createAsset must return a nonempty models array.');
  const ids = new Set();
  for (const model of value.models) {
    if (!/^[a-z0-9][a-z0-9-]{0,63}$/.test(model.id) || ids.has(model.id)) throw new Error(`Model IDs must be unique lowercase slugs: ${model.id}`);
    if (!(model.object instanceof THREE.Object3D)) throw new Error(`${model.id} needs a Three.js Object3D.`);
    objectBounds(model.object);
    ids.add(model.id);
  }
  const viewIDs = new Set();
  for (const view of value.views ?? []) {
    if (!/^[a-z0-9][a-z0-9-]{0,63}$/.test(view.id) || viewIDs.has(view.id) || ids.has(view.id)) throw new Error(`View IDs must be unique slugs: ${view.id}`);
    if (!(view.object instanceof THREE.Object3D)) throw new Error(`${view.id} needs a Three.js Object3D.`);
    objectBounds(view.object);
    viewIDs.add(view.id);
  }
  if (value.exportFrame) {
    const { pixels, center, width, height, margin } = value.exportFrame;
    if (!Array.isArray(pixels) || pixels.length !== 2 || !pixels.every(n => Number.isInteger(n) && n > 0 && n <= 4096)
        || !Array.isArray(center) || center.length !== 3 || !center.every(Number.isFinite)
        || !(width > 0 && height > 0 && margin >= 0) || ![width, height, margin].every(Number.isFinite)) {
      throw new Error('Invalid exportFrame dimensions.');
    }
  }
}

async function selectAsset(id, requestedView) {
  if (loading || exporting) return;
  loading = true;
  setBusy(true);
  if (preview) scene.remove(preview);
  preview = undefined;
  disposeAsset(asset);
  asset = undefined;
  entries = [];
  document.querySelector('#stats').textContent = '';
  document.querySelector('#output').textContent = '';
  const entry = catalog.find(item => item.id === id);
  let built;
  try {
    reportProgress(`Loading ${entry.label}…`);
    document.querySelector('#description').textContent = entry.description;
    const module = await import(entry.module);
    if (typeof module.createAsset !== 'function') throw new Error(`${entry.module} must export createAsset.`);
    built = await module.createAsset({ renderer, reportProgress });
    validateAsset(built);
    asset = built;
    entries = [...(asset.views ?? []), ...asset.models];
    viewSelect.replaceChildren(...entries.map(view => new Option(view.label ?? view.id, view.id)));
    showView(requestedView);
    reportProgress(`Ready · ${asset.models.length} exportable ${asset.models.length === 1 ? 'model' : 'models'}`);
  } catch (error) {
    disposeAsset(built);
    asset = undefined;
    reportProgress(`Could not build ${entry.label}: ${error.message}`, true);
    console.error(error);
    render();
  } finally {
    loading = false;
    setBusy(false);
  }
}

async function save(assetID, name, blob) {
  const response = await fetch(`/export/${assetID}/${name}`, { method: 'POST', body: blob });
  if (!response.ok) throw new Error(`Export ${name} failed: ${response.status}`);
}

async function exportAll() {
  if (!asset || exporting || loading) return;
  exporting = true;
  setBusy(true);
  const assetID = assetSelect.value;
  const savedCamera = camera.clone(), savedTarget = controls.target.clone();
  const clearColor = renderer.getClearColor(new THREE.Color()), clearAlpha = renderer.getClearAlpha();
  const exportScene = createStudio();
  const manifest = { asset: assetID, renderer: `Three.js ${THREE.REVISION}`, files: {}, frames: {} };
  try {
    for (const [index, model] of asset.models.entries()) {
      reportProgress(`Exporting ${model.label ?? model.id} · ${index + 1}/${asset.models.length}…`);
      const clone = model.object.clone(true);
      clone.traverse(node => { node.userData = {}; });
      const glb = await new GLTFExporter().parseAsync(clone, { binary: true });
      await save(assetID, `${model.id}.glb`, new Blob([glb], { type: 'model/gltf-binary' }));
      exportScene.add(clone);
      const bounds = objectBounds(clone), frame = asset.exportFrame;
      const pixels = frame?.pixels ?? [900, 900];
      const center = frame ? new THREE.Vector3(...frame.center) : bounds.getCenter(new THREE.Vector3());
      const distance = Math.max(20, bounds.getSize(new THREE.Vector3()).length() * 3);
      camera.position.copy(center).add(new THREE.Vector3(0, 0, distance));
      camera.up.set(0, 1, 0);
      camera.lookAt(center);
      camera.zoom = 1;
      camera.near = .01;
      camera.far = distance * 4;
      if (frame) {
        const height = Math.max(frame.height + 2 * frame.margin, (frame.width + 2 * frame.margin) / (pixels[0] / pixels[1]));
        camera.left = -height * pixels[0] / pixels[1] / 2;
        camera.right = -camera.left;
        camera.top = height / 2;
        camera.bottom = -height / 2;
        camera.updateProjectionMatrix();
      } else frameCamera(camera, clone, pixels[0] / pixels[1], center);
      renderer.setPixelRatio(1);
      renderer.setSize(...pixels, false);
      renderer.setClearColor(0, 0);
      renderer.render(exportScene, camera);
      const png = await new Promise((resolve, reject) => renderer.domElement.toBlob(blob => blob ? resolve(blob) : reject(new Error('PNG encoding failed')), 'image/png'));
      await save(assetID, `${model.id}.png`, png);
      manifest.files[model.key ?? model.id] = { glb: `models/${model.id}.glb`, png: `png/${model.id}.png` };
      manifest.frames[model.id] = { pixels, center: center.toArray(), worldUnitsPerPixel: (camera.top - camera.bottom) / pixels[1] };
      exportScene.remove(clone);
      await new Promise(requestAnimationFrame);
    }
    await save(assetID, 'manifest.json', new Blob([JSON.stringify(manifest, null, 2)], { type: 'application/json' }));
    reportProgress(`Export complete · ${asset.models.length} ${asset.models.length === 1 ? 'GLB' : 'GLBs'} + ${asset.models.length} transparent ${asset.models.length === 1 ? 'PNG' : 'PNGs'}`);
    document.querySelector('#output').textContent = `Saved to AssetFactory/assets/${assetID}/models/ and png/`;
  } catch (error) {
    reportProgress(error.message, true);
    console.error(error);
  } finally {
    camera.copy(savedCamera);
    controls.target.copy(savedTarget);
    renderer.setClearColor(clearColor, clearAlpha);
    exporting = false;
    controls.update();
    setBusy(false);
    resize();
  }
}

document.querySelector('#reload').onclick = () => location.reload();
assetSelect.onchange = () => selectAsset(assetSelect.value);
viewSelect.onchange = () => showView(viewSelect.value);
document.querySelector('#angle').onclick = () => resetCamera(true);
document.querySelector('#reset').onclick = () => resetCamera();
exportButton.onclick = exportAll;
document.querySelector('#background').onchange = event => {
  const mode = event.target.value;
  stage.dataset.background = mode;
  stage.style.backgroundColor = mode === 'dark' ? '#171b19' : mode === 'studio' ? '#d8d5ce' : '';
  renderer.setClearColor(mode === 'dark' ? 0x171b19 : 0xd8d5ce, mode === 'transparent' ? 0 : 1);
  render();
};

try {
  const registry = await loadJSON('/api/assets');
  catalog = registry.assets;
  if (registry.errors.length) console.warn('Skipped invalid asset manifests:', registry.errors);
  if (!catalog.length) throw new Error('No assets found. Add an assets/<name>/asset.json and module, then reload.');
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.setClearColor(0xd8d5ce, 1);
  stage.appendChild(renderer.domElement);
  scene = createStudio();
  camera = new THREE.OrthographicCamera(-1, 1, 1, -1, .01, 100);
  controls = new OrbitControls(camera, renderer.domElement);
  controls.minZoom = .15;
  controls.maxZoom = 10;
  controls.screenSpacePanning = true;
  controls.addEventListener('change', render);
  new ResizeObserver(resize).observe(stage);
  assetSelect.replaceChildren(...catalog.map(entry => new Option(entry.label, entry.id)));
  assetSelect.value = catalog.some(entry => entry.id === query.get('asset')) ? query.get('asset') : catalog[0].id;
  await selectAsset(assetSelect.value, query.get('view'));
  if (registry.errors.length) reportProgress(`${status.textContent} · ${registry.errors.length} invalid asset folders skipped (see console)`, true);
} catch (error) {
  reportProgress(error.message, true);
  console.error(error);
}
