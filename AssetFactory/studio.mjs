import * as THREE from 'three';

export async function loadJSON(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Could not load ${url}: ${response.status}`);
  return response.json();
}

export function createStudio() {
  const scene = new THREE.Scene();
  scene.add(new THREE.HemisphereLight(0xe3eaff, 0x55545a, 1.4));
  const key = new THREE.DirectionalLight(0xffffff, 3.2);
  key.position.set(-3.8, 6.25, 5.2);
  scene.add(key);
  const fill = new THREE.DirectionalLight(0xe7efff, .65);
  fill.position.set(4, 1.55, 6);
  scene.add(fill);
  return scene;
}

export function objectBounds(object) {
  object.updateMatrixWorld(true);
  const bounds = new THREE.Box3().setFromObject(object);
  if (bounds.isEmpty() || ![...bounds.min, ...bounds.max].every(Number.isFinite)) {
    throw new Error('Models need finite, nonempty geometry to preview and export.');
  }
  return bounds;
}

export function geometryStats(object) {
  let vertices = 0, triangles = 0;
  object.traverse(node => {
    if (!node.isMesh) return;
    const geometry = node.geometry;
    vertices += geometry.attributes.position?.count ?? 0;
    triangles += (geometry.index?.count ?? geometry.attributes.position?.count ?? 0) / 3;
  });
  return { vertices, triangles };
}

export function frameCamera(camera, object, aspect, target) {
  const bounds = objectBounds(object), center = target ?? bounds.getCenter(new THREE.Vector3());
  const inverse = camera.quaternion.clone().invert();
  let width = 0, height = 0;
  for (const x of [bounds.min.x, bounds.max.x]) {
    for (const y of [bounds.min.y, bounds.max.y]) {
      for (const z of [bounds.min.z, bounds.max.z]) {
        const point = new THREE.Vector3(x, y, z).sub(center).applyQuaternion(inverse);
        width = Math.max(width, Math.abs(point.x) * 2);
        height = Math.max(height, Math.abs(point.y) * 2);
      }
    }
  }
  const margin = Math.max(width, height, .1) * .1;
  const visibleHeight = Math.max(height + margin * 2, (width + margin * 2) / aspect, .1);
  camera.left = -visibleHeight * aspect / 2;
  camera.right = visibleHeight * aspect / 2;
  camera.top = visibleHeight / 2;
  camera.bottom = -visibleHeight / 2;
  camera.updateProjectionMatrix();
}

// View clones share geometry/materials. Dispose each resource only once.
export function disposeAsset(asset) {
  if (!asset) return;
  const geometries = new Set(), materials = new Set(), textures = new Set();
  for (const entry of [...(Array.isArray(asset.models) ? asset.models : []), ...(Array.isArray(asset.views) ? asset.views : [])]) {
    entry.object?.traverse(node => {
      if (node.geometry) geometries.add(node.geometry);
      for (const material of Array.isArray(node.material) ? node.material : [node.material]) {
        if (!material) continue;
        materials.add(material);
        for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
      }
    });
  }
  for (const resource of [...geometries, ...materials, ...textures]) resource.dispose();
  asset.dispose?.();
}
