import test from 'node:test';
import assert from 'node:assert/strict';
import {simulate,examples,cordic,bits} from '../assets/qr-hardware.js';
test('all six PEs consume values only after their producer cycle and match stream columns',()=>{
 const m=simulate();assert.equal(m.ops.length,26);
 for(const o of m.ops)for(const v of [o.a,o.b])if(v.producer){
  assert.ok(v.producer.cycle<o.cycle);
  assert.equal(v.producer.c,o.c);
  assert.equal(v.value,v.producer.calc.values[v.port]);
  const delayed=(o.pe.id==='23'&&v===o.a)||(o.pe.id==='34'&&v===o.a);
  assert.equal(o.cycle-v.producer.cycle,delayed?2:1);
 }
});
test('each pivot captures a direction word reused by all followers',()=>{
 const m=simulate();for(const o of m.ops){const pivot=m.ops.find(p=>p.pe===o.pe&&p.mode==='vector');assert.deepEqual(o.calc.dir,pivot.calc.dir);}
 assert.equal(m.arrivals.length,14);assert.equal(Math.max(...m.arrivals.map(a=>a.cycle)),10);
});
test('4 by 4 solve and negative-pivot example satisfy the original equations',()=>{
 for(const e of Object.values(examples)){const m=simulate(e);assert.ok(m.residual<.003);m.x.forEach((x,i)=>assert.ok(Math.abs(x-e.x[i])<.001));}
 assert.equal(cordic(-4,1).flip,1);
});
test('CORDIC vectoring and replay agree with an independent Givens rotation',()=>{
 for(const [x,y] of [[3,4],[-3,4],[3,-4],[-3,-4]]){
  const q=cordic(x,y);assert.ok(Math.abs(q.values[0]-5)<.0001);assert.ok(Math.abs(q.values[1])<.0001);
  const r=cordic(2,-1,q.dir);assert.ok(Math.abs(r.values[0]-(x*2-y)/5)<.0001);assert.ok(Math.abs(r.values[1]-(-y*2-x)/5)<.0001);
 }
});
test('back substitution reuses only completed solutions and gives consistent products',()=>{
 const m=simulate();for(const b of m.back){assert.ok(b.cycle>10);for(const t of b.terms){assert.ok(t.j>b.r);assert.equal(t.x,b.before[t.j]);assert.equal(t.value,t.a*t.x);}assert.equal(b.numerator,m.z[b.r]-b.sum);}
 assert.equal(m.back.length,12);assert.equal(m.back.at(-1).cycle,22);assert.equal(bits(-1),'1'.repeat(25));
});
