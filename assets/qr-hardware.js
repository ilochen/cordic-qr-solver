// Arithmetic follows dsp_final.m; timing is the user-selected one-cycle PE model.
export const PES = [
 {id:'12',row:0,other:1,pivot:0,offset:1,x:200,y:180},
 {id:'13',row:0,other:2,pivot:0,offset:2,x:410,y:180},
 {id:'14',row:0,other:3,pivot:0,offset:3,x:620,y:180},
 {id:'23',row:1,other:2,pivot:1,offset:3,x:410,y:380},
 {id:'24',row:1,other:3,pivot:1,offset:4,x:620,y:380},
 {id:'34',row:2,other:3,pivot:2,offset:5,x:620,y:580}
];
const S=2**19,W=2**25;
export const wrap=v=>((v+W/2)%W+W)%W-W/2;
export const bits=v=>((v+W)%W).toString(2).padStart(25,'0');
export function cordic(x,y,directions=null){
 let X=wrap(Math.floor(x*S)),Y=wrap(Math.floor(y*S));
 const input=[X,Y],flip=directions?directions[0]:Number(X<0),dir=[flip],stages=[];
 if(flip){X=wrap(-X);Y=wrap(-Y);} const coarse=[X,Y];
 let gain=1;
 for(let k=0;k<18;k++){
  const d=directions?(directions[k+1]?1:-1):(Y>0?1:-1),sx=Math.floor(X/2**k),sy=Math.floor(Y/2**k);
  const nx=wrap(X+d*sy),ny=wrap(Y-d*sx);
  stages.push({k,d,x:X,y:Y,sx,sy,nx,ny});dir.push(Number(d===1));X=nx;Y=ny;gain*=Math.sqrt(1+2**(-2*k));
 }
 const out=[wrap(Math.floor(X/gain)),wrap(Math.floor(Y/gain))];
 return {input,coarse,dir,flip,stages,gain,out,values:out.map(v=>v/S)};
}
export const examples={
 regular:{A:[[4,1,2,0],[1,5,0,1],[2,0,6,1],[0,1,1,4]],x:[1,-1,2,.5]},
 negative:{A:[[-4,1,2,0],[1,5,0,1],[2,0,6,1],[0,1,1,4]],x:[1,-1,2,.5]}
};
export function simulate(example=examples.regular){
 const A=example.A.map(r=>r.slice()),b=A.map(r=>r.reduce((s,v,j)=>s+v*example.x[j],0)),inputs=A.map((r,i)=>[...r,b[i]]);
 const ops=[],lookup=new Map(),dirs={};
 const source=(id,c,port)=>{const o=lookup.get(`${id}:${c}`);if(!o)throw Error(`Missing ${id}:${c}`);return {value:o.calc.values[port],producer:o,port};};
 for(let cycle=1;cycle<=9;cycle++)for(const pe of PES){
  const c=cycle-pe.offset;if(c<pe.pivot||c>4)continue;
  let a,b;
  if(pe.id==='12'){a={value:inputs[0][c]};b={value:inputs[1][c]};}
  if(pe.id==='13'){a=source('12',c,0);b={value:inputs[2][c]};}
  if(pe.id==='14'){a=source('13',c,0);b={value:inputs[3][c]};}
  if(pe.id==='23'){a=source('12',c,1);b=source('13',c,1);}
  if(pe.id==='24'){a=source('23',c,0);b=source('14',c,1);}
  if(pe.id==='34'){a=source('23',c,1);b=source('24',c,1);}
  const mode=c===pe.pivot?'vector':'rotate',calc=cordic(a.value,b.value,mode==='vector'?null:dirs[pe.id]);
  if(mode==='vector')dirs[pe.id]=calc.dir;
  const op={pe,cycle,c,a,b,mode,calc};ops.push(op);lookup.set(`${pe.id}:${c}`,op);
 }
 const R=Array.from({length:4},()=>Array(4).fill(0)),z=Array(4),arrivals=[];
 for(let r=0;r<4;r++)for(let c=r;c<5;c++){
  const id=['14','24','34','34'][r],port=r===3?1:0,o=lookup.get(`${id}:${c}`),value=o.calc.values[port],cycle=o.cycle+(r===3?1:0);
  if(c===4)z[r]=value;else R[r][c]=value;
  arrivals.push({r,c,value,cycle});
 }
 const back=[],x=Array(4).fill(null);let cycle=11;
 for(let r=3;r>=0;r--){
  const terms=Array.from({length:3-r},(_,k)=>{const j=r+1+k;return {j,a:R[r][j],x:x[j],value:R[r][j]*x[j]};}),sum=terms.reduce((s,t)=>s+t.value,0),numerator=z[r]-sum,quotient=Math.floor(numerator/R[r][r]*4096)/4096;
  for(const phase of ['multiply','subtract','divide'])back.push({cycle:cycle++,r,phase,terms,sum,numerator,quotient,before:x.slice()});
  x[r]=quotient;
 }
 const residual=Math.hypot(...A.map((row,i)=>row.reduce((s,a,j)=>s+a*x[j],0)-b[i]));
 return {A,b,inputs,ops,lookup,R,z,arrivals,back,x,residual,last:22};
}
