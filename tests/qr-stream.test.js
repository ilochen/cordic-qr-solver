import test from 'node:test';
import assert from 'node:assert/strict';
import {createStream,snapshot} from '../assets/qr-stream.js';
test('overlap preserves banks until solve completes',()=>{
 const jobs=createStream();
 for(const j of jobs){const next=jobs.find(n=>n.bank===j.bank&&n.id>j.id);if(next)assert.ok(next.start+3>=j.end);}
 const state=snapshot(jobs,12.5);
 assert.equal(state.banks[0].status,'solving');assert.equal(state.banks[1].status,'loading');
 assert.equal(state.banks[0].x[3],jobs[0].model.x[3]);assert.equal(state.banks[0].x[0],null);assert.equal(state.banks[1].z[3],null);
});
test('alternating systems solve independently and retain physical registers until overwritten',()=>{
 const jobs=createStream();
 for(const job of jobs){const state=snapshot(jobs,job.end).banks[job.bank];assert.equal(state.job.id,job.id);assert.deepEqual(state.x,job.model.x);assert.ok(job.model.residual<.01);}
 assert.deepEqual(snapshot(jobs,17).banks[0].x,jobs[0].model.x);
});
