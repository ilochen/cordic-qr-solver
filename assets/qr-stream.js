import {simulate,examples} from './qr-hardware.js';
// Functional overlap schedule, not a cycle-accurate RTL trace.
export function createStream(){
 const inputs=[examples.regular,{A:[[3,1,0,1],[1,4,1,0],[0,1,5,1],[1,0,1,3]],x:[.5,1,-1,2]},examples.negative,{A:[[5,0,1,1],[0,3,1,0],[1,1,4,1],[1,0,1,5]],x:[-1,.5,1,1]}];
 return inputs.map((input,i)=>({id:i+1,bank:i%2,start:i*7,ready:i*7+10,end:i*7+14,model:simulate(input)}));
}
export function snapshot(jobs,t){
 const banks=[0,1].map(bank=>{
  const job=jobs.filter(j=>j.bank===bank&&t>=j.start+3).at(-1);
  if(!job)return {job:null,R:Array.from({length:4},()=>Array(4).fill(null)),z:Array(4).fill(null),x:Array(4).fill(null),status:'empty'};
  const R=Array.from({length:4},(_,r)=>Array.from({length:4},(_,c)=>c<r?0:null)),z=Array(4).fill(null),x=Array(4).fill(null);
  // Physical registers retain old contents until their next write.
  for(const owner of jobs.filter(j=>j.bank===bank&&j.id<=job.id)){
   for(const a of owner.model.arrivals)if(t>=owner.start+a.cycle){if(a.c===4)z[a.r]=a.value;else R[a.r][a.c]=a.value;}
   for(let row=3;row>=0;row--)if(t>=owner.ready+4-row)x[row]=owner.model.x[row];
  }
  return {job,R,z,x,status:t<job.ready?'loading':t<job.end?'solving':'complete'};
 });
 return {banks,compute:jobs.find(j=>t>=j.ready&&t<j.end),input:jobs.filter(j=>t>=j.start&&t<j.start+10).at(-1)};
}
