import * as THREE from 'three';
// Seeded, tileable grit: real material maps, embedded in exported GLBs.
export function createSandpaper(renderer){
 const n=128,heights=new Float32Array(n*n);let seed=73193;
 const rand=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
 for(let i=0;i<heights.length;i++)heights[i]=Math.pow(rand(),1.7);
 const h=(x,y)=>heights[((y+n)%n)*n+(x+n)%n];
 const color=document.createElement('canvas'),normal=document.createElement('canvas');color.width=color.height=normal.width=normal.height=n;
 const cc=color.getContext('2d'),nc=normal.getContext('2d'),ci=cc.createImageData(n,n),ni=nc.createImageData(n,n);
 for(let y=0;y<n;y++)for(let x=0;x<n;x++){
  const i=(y*n+x)*4,v=h(x,y),shade=23+32*v;
  ci.data.set([shade,shade,shade,255],i);
  const dx=(h(x+1,y)-h(x-1,y))*1.65,dy=(h(x,y+1)-h(x,y-1))*1.65,l=Math.hypot(dx,dy,1);
  ni.data.set([127.5*(1-dx/l),127.5*(1-dy/l),127.5*(1+1/l),255],i);
 }
 cc.putImageData(ci,0,0);nc.putImageData(ni,0,0);
 const map=new THREE.CanvasTexture(color),normalMap=new THREE.CanvasTexture(normal);map.colorSpace=THREE.SRGBColorSpace;
 for(const t of [map,normalMap]){t.wrapS=t.wrapT=THREE.RepeatWrapping;t.anisotropy=Math.min(8,renderer.capabilities.getMaxAnisotropy());}
 const material=new THREE.MeshStandardMaterial({name:'Black coarse sandpaper',map,normalMap,normalScale:new THREE.Vector2(.85,.85),roughness:.94,metalness:0});
 return group=>group.traverse(mesh=>{
  if(!mesh.isMesh)return;
  const g=mesh.geometry,p=g.attributes.position,no=g.attributes.normal,uv=[];
  for(let i=0;i<p.count;i++){
   const x=p.getX(i),y=p.getY(i),z=p.getZ(i);
   // Planar front/back and dominant-axis projection on the sidewalls.
   if(Math.abs(no.getZ(i))>.5)uv.push(x/1.8,y/1.8);
   else if(Math.abs(no.getX(i))>Math.abs(no.getY(i)))uv.push(z/1.8,y/1.8);
   else uv.push(x/1.8,z/1.8);
  }
  // All front vertices share one projection, including steep crown slopes.
  if(mesh===group.children[0]||mesh===group.children[1])for(let i=0;i<p.count;i++){uv[i*2]=p.getX(i)/1.8;uv[i*2+1]=p.getY(i)/1.8;}
  g.setAttribute('uv',new THREE.Float32BufferAttribute(uv,2));mesh.material=material;
 });
}
