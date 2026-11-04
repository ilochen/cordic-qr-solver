import test from 'node:test';
import assert from 'node:assert/strict';
import {fixedQR,wordBits,roundDiv} from '../assets/qr-fixed.js';
const A=[[4,1,2],[1,3,0],[2,0,5]],b=[4,7,-3];
test('two’s complement and rounding policies',()=>{
  assert.equal(wordBits(-1n),'1'.repeat(24));
  assert.equal(wordBits(-2n).slice(-4),'1110');
  assert.equal(-3n >> 1n,-2n);
  assert.equal(roundDiv(-3n,2n),-2n);assert.equal(roundDiv(3n,2n),2n);
});
test('every CORDIC lane uses the boundary direction and OLD source words',()=>{
  const r=fixedQR(A,b);
  for(const s of r.trace.filter(t=>t.kind==='add')) for(const lane of s.lanes){
    assert.equal(lane.sx,lane.x >> BigInt(s.k));assert.equal(lane.sy,lane.y >> BigInt(s.k));
    assert.equal(lane.nx,lane.x+BigInt(s.d)*lane.sy);assert.equal(lane.ny,lane.y-BigInt(s.d)*lane.sx);
    assert.equal(s.d,s.lanes[0].y>=0n?1:-1);
  }
});
test('fixed QR solution and residual agree with original system',()=>{
  for(const fraction of [8,14,18])for(const iterations of [8,14,18]){
    const r=fixedQR(A,b,{fraction,iterations});assert.ok(!r.singular);
    assert.ok(r.residual<.2);assert.ok(Math.hypot(...r.x.map((v,i)=>v-[1,2,-1][i]))<.1);
    const actual=Math.hypot(...A.map((row,i)=>row.reduce((s,v,j)=>s+v*r.x[j],0)-b[i]));assert.equal(r.residual,actual);
  }
});
test('negative pivot coarse rotation and identity work',()=>{
  for(const m of [[[-3,2,1],[2,5,-1],[1,-1,4]],[[1,0,0],[0,1,0],[0,0,1]],[[0,1,0],[1,0,0],[0,0,1]]]){
    const rhs=m.map(row=>row.reduce((s,v,i)=>s+v*[1,2,-1][i],0)),r=fixedQR(m,rhs);assert.ok(!r.singular);assert.ok(r.residual<.01);
  }
});
test('back substitution shows every product, accumulation and division',()=>{
  const r=fixedQR(A,b),t=r.trace;
  assert.equal(t.filter(s=>s.kind==='back-mul').length,3);
  assert.equal(t.filter(s=>s.kind==='back-div').length,3);
  assert.deepEqual(t.filter(s=>s.kind==='back-store').map(s=>s.row),[2,1,0]);
  for(const s of t.filter(s=>s.kind==='back-mul'))assert.equal(s.term,roundDiv(s.a*s.x,BigInt(r.scale)));
  for(const s of t.filter(s=>s.kind==='back-div'))assert.equal(s.quotient,roundDiv(s.numerator*BigInt(r.scale),s.divisor));
});
test('singular input and overflow have explicit outcomes',()=>{
  assert.ok(fixedQR([[1,2,3],[2,4,6],[3,6,9]],[2,4,6]).singular);
  assert.throws(()=>fixedQR([[999999,1,2],[1,3,0],[2,0,5]],b),/overflow/);
  assert.throws(()=>fixedQR([[400,400,400],[400,400,400],[400,400,400]],[400,400,400]),/overflow/);
});
