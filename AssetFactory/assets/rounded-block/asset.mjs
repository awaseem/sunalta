import * as THREE from 'three';

// Keep source models at their intended export origin. The viewer frames them.
export async function createAsset({ reportProgress }) {
  reportProgress('Building rounded block…');
  const outline = new THREE.Shape();
  const width = 2, height = 3, radius = .22;
  outline.moveTo(-width / 2 + radius, -height / 2);
  outline.lineTo(width / 2 - radius, -height / 2);
  outline.quadraticCurveTo(width / 2, -height / 2, width / 2, -height / 2 + radius);
  outline.lineTo(width / 2, height / 2 - radius);
  outline.quadraticCurveTo(width / 2, height / 2, width / 2 - radius, height / 2);
  outline.lineTo(-width / 2 + radius, height / 2);
  outline.quadraticCurveTo(-width / 2, height / 2, -width / 2, height / 2 - radius);
  outline.lineTo(-width / 2, -height / 2 + radius);
  outline.quadraticCurveTo(-width / 2, -height / 2, -width / 2 + radius, -height / 2);
  const geometry = new THREE.ExtrudeGeometry(outline, {
    depth: .5, bevelEnabled: true, bevelThickness: .12, bevelSize: .12,
    bevelSegments: 6, curveSegments: 24, steps: 1,
  });
  geometry.translate(0, 0, -.25);
  const material = new THREE.MeshStandardMaterial({ color: 0x4c776e, roughness: .38, metalness: .08 });
  const object = new THREE.Group();
  object.name = 'Rounded block';
  object.add(new THREE.Mesh(geometry, material));
  return { models: [{ id: 'rounded-block', label: 'Rounded block', object }] };
}
