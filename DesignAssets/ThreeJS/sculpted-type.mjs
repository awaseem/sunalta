import * as THREE from 'three';

export const DEFAULT_PROFILE={peak:.198,slope:.31,rounding:.022,blend:.018,edge_drop:.007,edge_width:.008,floor:.052,floor_softness:.008,back:.012};
const dist=(p,a,b)=>{const dx=b[0]-a[0],dy=b[1]-a[1],n=dx*dx+dy*dy,t=n?Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/n)):0;return Math.hypot(p[0]-a[0]-t*dx,p[1]-a[1]-t*dy);};
const minDist=(p,segments)=>{let d=Infinity;for(const [a,b] of segments)d=Math.min(d,dist(p,a,b));return d;};
const softplus=x=>Math.max(x,0)+Math.log1p(Math.exp(-Math.abs(x)));
const cross=(a,b,c)=>(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);
const edgeKey=(a,b)=>a<b?`${a},${b}`:`${b},${a}`;
function bounds(points){let x0=Infinity,y0=Infinity,x1=-Infinity,y1=-Infinity;for(const [x,y] of points){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}return {low:[x0,y0],size:[x1-x0,y1-y0]};}
function edges(triangles){const map=new Map();for(const t of triangles)for(let k=0;k<3;k++){const a=t[k],b=t[(k+1)%3],key=edgeKey(a,b);const e=map.get(key);if(e)e.count++;else map.set(key,{a,b,count:1});}return map;}
function outline(font,char,curveSegments){
 if(!font.data.glyphs[char])throw Error(`Font lacks ${JSON.stringify(char)}; refusing replacement glyph`);
 const g=new THREE.ShapeGeometry(font.generateShapes(char,1),curveSegments),p=g.attributes.position,index=g.index?.array;
 if(!index?.length){g.dispose();throw Error(`No filled outline for ${char}`);}
 const points=[],map=new Map(),remap=[];
 for(let i=0;i<p.count;i++){const x=p.getX(i),y=p.getY(i),key=`${x.toFixed(8)},${y.toFixed(8)}`;if(!map.has(key)){map.set(key,points.length);points.push([x,y]);}remap.push(map.get(key));}
 const triangles=[];
 for(let i=0;i<index.length;i+=3){let t=[remap[index[i]],remap[index[i+1]],remap[index[i+2]]];const area=cross(...t.map(v=>points[v]));const q=t.map(v=>points[v]),longest=Math.max(...q.map((a,k)=>Math.hypot(a[0]-q[(k+1)%3][0],a[1]-q[(k+1)%3][1])));if(Math.abs(area)<1e-12||Math.abs(area)/longest<1e-7)continue;if(area<0)t=[t[0],t[2],t[1]];triangles.push(t);}
 g.dispose();return {points,triangles};
}
function conformSource(points, triangles) {
 const count=points.length,next=[];
 for(const tri of triangles){const polygon=[];
  for(let k=0;k<3;k++){const a=tri[k],b=tri[(k+1)%3],A=points[a],B=points[b],dx=B[0]-A[0],dy=B[1]-A[1],length2=dx*dx+dy*dy,cuts=[];polygon.push(a);
   for(let i=0;i<count;i++){if(i===a||i===b)continue;const P=points[i],t=((P[0]-A[0])*dx+(P[1]-A[1])*dy)/length2;if(t>1e-8&&t<1-1e-8&&dist(P,A,B)<1e-7)cuts.push([t,i]);}
   cuts.sort((a,b)=>a[0]-b[0]);polygon.push(...cuts.map(p=>p[1]));
  }
  if(polygon.length===3){next.push(tri);continue;}
  const center=points.length;points.push([0,1].map(k=>tri.reduce((sum,i)=>sum+points[i][k],0)/3));
  for(let k=0;k<polygon.length;k++)next.push([polygon[k],polygon[(k+1)%polygon.length],center]);
 }
 return next;
}
function refine(points,triangles,spacing,maxVertices){
 // Shared edge midpoints keep neighbouring triangles conforming: no T-junctions.
 for(let pass=0;pass<24;pass++){
  const mids=new Map();for(const [key,{a,b}] of edges(triangles)){if(Math.hypot(points[a][0]-points[b][0],points[a][1]-points[b][1])>spacing){mids.set(key,points.length);points.push([(points[a][0]+points[b][0])/2,(points[a][1]+points[b][1])/2]);if(points.length>maxVertices)throw Error('Mesh budget exceeded; increase spacing');}}
  if(!mids.size)return triangles;
  const next=[];
  for(const v of triangles){const m=v.map((a,k)=>mids.get(edgeKey(a,v[(k+1)%3]))),n=m.filter(x=>x!==undefined).length;
   if(!n){next.push(v);continue;}
   if(n===3){next.push([v[0],m[0],m[2]],[m[0],v[1],m[1]],[m[2],m[1],v[2]],[m[0],m[1],m[2]]);continue;}
   if(n===1){const k=m.findIndex(x=>x!==undefined),a=v[k],b=v[(k+1)%3],c=v[(k+2)%3];next.push([a,m[k],c],[m[k],b,c]);continue;}
   const k=(m.findIndex(x=>x===undefined)+1)%3,a=v[k],b=v[(k+1)%3],c=v[(k+2)%3],ab=m[k],bc=m[(k+1)%3];
   next.push([b,bc,ab],[a,ab,c],[ab,bc,c]);
  }
  triangles=next;
 }
 throw Error('Refinement did not converge');
}
function guides(recipe,points,boundary){
 const {low,size}=bounds(points),paths=[];
 if(recipe.kind==='stem'){
  const y=low[1]+(recipe.sample_v??.3)*size[1],xs=[];
  for(const [a,b] of boundary)if((a[1]>y)!==(b[1]>y))xs.push(a[0]+(y-a[1])*(b[0]-a[0])/(b[1]-a[1]));
  if(xs.length!==2)throw Error('Stem sample must intersect exactly one stroke');
  const x=(xs[0]+xs[1])/2;return [[[x,low[1]-.1*size[1]],[x,low[1]+1.1*size[1]]]];
 }
 for(const path of recipe.paths??[]){let uv=[];
  if(path.type==='polyline')uv=path.points;
  else if(path.type==='ellipse'){for(let i=0;i<=360;i++){const t=(path.start??0)+((path.end??2*Math.PI)-(path.start??0))*i/360;uv.push([path.cx+path.rx*Math.cos(t),path.cy+path.ry*Math.sin(t)]);}}
  else if(path.type==='bezier'){for(const [a,b,c,d] of path.segments)for(let i=0;i<=80;i++){const t=i/80,u=1-t;uv.push([0,1].map(k=>u*u*u*a[k]+3*u*u*t*b[k]+3*u*t*t*c[k]+t*t*t*d[k]));}}
  else throw Error('Unknown guide path type');
  if(uv.length<2||!uv.every(p=>p.length===2&&p.every(Number.isFinite)))throw Error('Invalid guide path');
  paths.push(uv.map(p=>p.map((v,k)=>low[k]+v*size[k])));
 }
 if(!paths.length)throw Error('A ridge recipe must contain paths');return paths;
}
export function buildGlyph(font,char,recipe,options={}){
 const o={height:3.712,condense:.6551724138,heightMode:'cap',referenceGlyph:'H',spacing:.045,curveSegments:24,maxVertices:180000,...options};
 if(!recipe)throw Error(`Missing ridge recipe for ${char}`);
 if(!(o.height>0&&o.condense>0&&o.spacing>0)||!['cap','uniform'].includes(o.heightMode))throw Error('Invalid dimensions or heightMode');
 const profile={...DEFAULT_PROFILE,...o.profile,...recipe.profile};
 if(!Object.values(profile).every(Number.isFinite)||!['slope','rounding','blend','edge_width','floor_softness'].every(k=>profile[k]>0)||!(profile.back>=0&&profile.back<profile.floor&&profile.floor<profile.peak))throw Error('Invalid surface profile');
 let {points,triangles}=outline(font,char,o.curveSegments);const bb=bounds(points),ref=o.heightMode==='uniform'?bb:bounds(outline(font,o.referenceGlyph,o.curveSegments).points),scale=o.height/ref.size[1];
 points=points.map(([x,y])=>[(x-bb.low[0]-bb.size[0]/2)*scale*o.condense,(y-ref.low[1])*scale]);
 triangles=conformSource(points,triangles);
 const sourceEdges=edges(triangles),boundary=[...sourceEdges.values()].filter(e=>e.count===1).map(e=>[points[e.a],points[e.b]]);
 const paths=guides(recipe,points,boundary),segments=paths.map(path=>path.slice(1).map((p,i)=>[path[i],p]));
 triangles=refine(points,triangles,o.spacing,o.maxVertices);
 const finalEdges=edges(triangles);if([...finalEdges.values()].some(e=>e.count>2))throw Error('Non-manifold front');
 const degree=new Map();for(const e of finalEdges.values())if(e.count===1){degree.set(e.a,(degree.get(e.a)??0)+1);degree.set(e.b,(degree.get(e.b)??0)+1);}if([...degree.values()].some(n=>n!==2))throw Error('Non-manifold boundary vertex');
 const heightAt=p=>{
  if(o.flat)return (profile.floor+profile.peak)/2;
  const hs=segments.map(s=>{const d=minDist(p,s);return profile.peak-profile.slope*(Math.hypot(d,profile.rounding)-profile.rounding);});
  const max=Math.max(...hs);let h=max+profile.blend*Math.log(hs.reduce((sum,v)=>sum+Math.exp((v-max)/profile.blend),0));
  h-=profile.edge_drop*Math.exp(-minDist(p,boundary)/profile.edge_width);
  return profile.floor+profile.floor_softness*softplus((h-profile.floor)/profile.floor_softness);
 };
 const heights=points.map(heightAt);
 const make=(pos,idx)=>{const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));if(idx)g.setIndex(idx);g.computeVertexNormals();g.computeBoundingBox();return g;};
 const front=make(points.flatMap((p,i)=>[...p,heights[i]]),triangles.flat());
 const normals=[];const eps=.0015;
 for(const [x,y] of points){const dx=(heightAt([x+eps,y])-heightAt([x-eps,y]))/(2*eps),dy=(heightAt([x,y+eps])-heightAt([x,y-eps]))/(2*eps),length=Math.hypot(dx,dy,1);normals.push(-dx/length,-dy/length,1/length);}
 front.setAttribute('normal',new THREE.Float32BufferAttribute(normals,3));
 const back=make(points.flatMap(p=>[...p,profile.back]),triangles.flatMap(t=>[t[2],t[1],t[0]]));
 const walls=[];for(const {a,b,count} of finalEdges.values())if(count===1){const A=[...points[a],heights[a]],B=[...points[b],heights[b]],C=[...points[b],profile.back],D=[...points[a],profile.back];walls.push(...A,...D,...B,...B,...D,...C);}
 const side=make(walls);
 const faceMaterial=new THREE.MeshStandardMaterial({color:new THREE.Color().setRGB(.31,.35,.40,THREE.LinearSRGBColorSpace),metalness:.18,roughness:.48,...o.material});
 const sideMaterial=new THREE.MeshStandardMaterial({color:new THREE.Color().setRGB(.10,.125,.16,THREE.LinearSRGBColorSpace),metalness:.22,roughness:.51});
 const group=new THREE.Group();group.name=`Glyph ${char}`;group.add(new THREE.Mesh(front,faceMaterial),new THREE.Mesh(back,sideMaterial),new THREE.Mesh(side,sideMaterial));
 group.userData={char,font:font.data.familyName,bounds:bounds(points),paths,profile,vertices:points.length,triangles:triangles.length,recipeQuality:recipe.quality??'task supplied'};
 return group;
}
export function addGuideOverlay(glyph){const overlay=new THREE.Group();overlay.name='Guide overlay';for(const path of glyph.userData.paths){const geometry=new THREE.BufferGeometry().setFromPoints(path.map(([x,y])=>new THREE.Vector3(x,y,.24)));overlay.add(new THREE.Line(geometry,new THREE.LineBasicMaterial({color:0xff6b20,depthTest:false})));}glyph.add(overlay);return overlay;}
export function frameCamera(camera,width,height,pixels=[600,900],margin=.45,center=[0,1.856]){const aspect=pixels[0]/pixels[1],h=Math.max(height+2*margin,(width+2*margin)/aspect),w=h*aspect;camera.left=-w/2;camera.right=w/2;camera.top=h/2;camera.bottom=-h/2;camera.position.set(center[0],center[1],18);camera.lookAt(center[0],center[1],0);camera.updateProjectionMatrix();return {pixels,baseline_y_from_top:pixels[1]*(.5+center[1]/h),world_units_per_pixel:h/pixels[1]};}
export function createStudio(){const scene=new THREE.Scene();scene.add(new THREE.HemisphereLight(0xe3eaff,0x55545a,1.4));const key=new THREE.DirectionalLight(0xffffff,3.2);key.position.set(-3.8,6.25,5.2);scene.add(key);const fill=new THREE.DirectionalLight(0xe7efff,.65);fill.position.set(4,1.55,6);scene.add(fill);const camera=new THREE.OrthographicCamera(-2,2,3,-3,.01,100);frameCamera(camera,2,3.712);return {scene,camera};}
export function disposeGlyph(group){const materials=new Set();group.traverse(o=>{o.geometry?.dispose();if(o.material)for(const mat of Array.isArray(o.material)?o.material:[o.material])materials.add(mat);});for(const mat of materials)mat.dispose();group.removeFromParent();}
