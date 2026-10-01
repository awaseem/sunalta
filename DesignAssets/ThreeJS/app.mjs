import * as THREE from 'three';
import {createSandpaper} from './sandpaper.mjs';
import {GLTFExporter} from './vendor/GLTFExporter.js';
import {OrbitControls} from './vendor/OrbitControls.js';
import {buildGlyph,createStudio,frameCamera} from './sculpted-type.mjs';
import {Font} from './vendor/FontLoader.js';
const status=document.querySelector('#status'),stage=document.querySelector('#stage');
try{
const font=new Font(await(await fetch('./font.json')).json()),config=await(await fetch('./clock-config.json')).json(),presets=await(await fetch('./guide-recipes.json')).json();
const recipes={...presets.presets['latin-seeds'].glyphs,...config.guides};recipes[':']={kind:'paths',paths:[{type:'polyline',points:[[.5,-.1],[.5,1.1]]}]};
const {scene,camera}=createStudio(),root=new THREE.Group();scene.add(root);
const renderer=new THREE.WebGLRenderer({antialias:true,alpha:true});renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.setClearColor(0,0);stage.appendChild(renderer.domElement);
await new Promise(requestAnimationFrame);
const applySandpaper=createSandpaper(renderer);
const glyphs={};for(const char of '0123456789:'){
 status.textContent=`Building ${char}…`;await new Promise(requestAnimationFrame);
 const g=buildGlyph(font,char,recipes[char],{height:config.height,condense:config.condense,heightMode:char===':'?'cap':'uniform',spacing:.06,profile:config.profile});
 if(char===':'){const b=g.userData.bounds,dy=config.height/2-b.low[1]-b.size[1]/2;for(const mesh of g.children)mesh.geometry.translate(0,dy,0);g.userData.bounds.low[1]+=dy;}
 applySandpaper(g);glyphs[char]=g;
}
const width=char=>glyphs[char].userData.bounds.size[0],copy=char=>glyphs[char].clone(true);
const controls=new OrbitControls(camera,renderer.domElement);
controls.minZoom=.2;controls.maxZoom=8;controls.screenSpacePanning=true;
controls.addEventListener('change',()=>{if(!exporting)renderer.render(scene,camera);});
let mode='set',exporting=false;
function row(text,y,scale=1,gap=.14,cx=0){const list=[...text],w=list.reduce((s,c)=>s+width(c)*scale,0)+gap*(list.length-1);let x=cx-w/2;for(const c of list){const g=copy(c);g.scale.setScalar(scale);g.position.set(x+width(c)*scale/2,y,0);root.add(g);x+=width(c)*scale+gap;}}
function layout(reset=true){root.clear();root.rotation.set(0,0,0);root.position.set(0,0,0);if(mode==='set'){row('01234',4.4);row('56789',0);row(':',-2.6,.60);}else{row('12:38',0,1,.12);}if(reset)resetCamera();else render();}
function render(){if(!exporting)renderer.render(scene,camera);}
function resize(){if(exporting)return;const w=stage.clientWidth,h=stage.clientHeight;renderer.setPixelRatio(Math.min(devicePixelRatio,2));renderer.setSize(w,h,false);const aspect=w/h,fh=Math.max((mode==='set'?11.5:4.6)+1,((mode==='set'?8:10)+1)/aspect);camera.left=-fh*aspect/2;camera.right=fh*aspect/2;camera.top=fh/2;camera.bottom=-fh/2;camera.updateProjectionMatrix();render();}
function resetCamera(angle=false){const cy=mode==='set'?2.45:1.856;camera.zoom=1;camera.up.set(0,1,0);controls.target.set(0,cy,0);camera.position.set(angle?5:0,cy,angle?17.3:18);camera.lookAt(controls.target);controls.update();resize();}
document.querySelector('#view').onchange=e=>{mode=e.target.value;layout();};
document.querySelector('#angle').onclick=()=>resetCamera(true);
document.querySelector('#reset').onclick=()=>resetCamera();
addEventListener('resize',resize);
const manifest={font:'Impact approximation, not Obviously',renderer:'Three.js 0.186.1',material:'Black coarse sandpaper, embedded color and normal maps',files:{},frames:{}};
async function save(name,blob){const response=await fetch('/export/'+name,{method:'POST',body:blob});if(!response.ok)throw Error(`Export failed: ${name}`);}
async function png(name,object,pixels,commonWidth){const clone=object.clone(true);clone.traverse(o=>o.userData={});const glb=await new GLTFExporter().parseAsync(clone,{binary:true});await save(name.replace('.png','.glb'),new Blob([glb],{type:'model/gltf-binary'}));root.clear();root.rotation.set(0,0,0);root.add(object);renderer.setPixelRatio(1);renderer.setSize(...pixels,false);const frame=frameCamera(camera,commonWidth,config.height,pixels,.45,[0,config.height/2]);renderer.render(scene,camera);const blob=await new Promise((resolve,reject)=>renderer.domElement.toBlob(b=>b?resolve(b):reject(Error('PNG encoding failed')),'image/png'));await save(name,blob);return frame;}
document.querySelector('#export').onclick=async()=>{const button=document.querySelector('#export');button.disabled=true;const savedCamera=camera.clone(),savedTarget=controls.target.clone();controls.enabled=false;exporting=true;camera.zoom=1;try{
 const commonWidth=Math.max(...Object.keys(glyphs).map(width));
 for(const c of '0123456789:'){status.textContent=`Exporting ${c}…`;const name=(c===':'?'colon':'digit-'+c)+'.png';manifest.frames.glyph=await png(name,copy(c),[600,900],commonWidth);manifest.files[c]='png/'+name;await new Promise(requestAnimationFrame);}
 await save('manifest.json',new Blob([JSON.stringify(manifest,null,2)],{type:'application/json'}));status.textContent='Export complete · 11 PNGs + 11 textured GLBs saved · shared sizing and baseline';
}catch(e){status.textContent=e.message;console.error(e);}finally{exporting=false;button.disabled=false;layout(false);camera.copy(savedCamera);controls.target.copy(savedTarget);controls.enabled=true;controls.update();resize();}};
layout();document.querySelector('#export').disabled=false;status.textContent='Ready · 0–9 and colon · real meshes with continuous ridges';
}catch(e){status.textContent='Could not render: '+e.message;console.error(e);}
