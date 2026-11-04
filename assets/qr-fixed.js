// Integer reference datapath. Stored numbers are signed W-bit integers / 2^F.
// Widened products are requantized with round-to-nearest, ties away from zero.
export function roundDiv(a, b) {
  if (b === 0n) throw Error('Division by zero');
  const sign = (a < 0n) !== (b < 0n) ? -1n : 1n;
  a = a < 0n ? -a : a; b = b < 0n ? -b : b;
  return sign * ((a + b / 2n) / b);
}
export function wordBits(value, width = 24) {
  return BigInt.asUintN(width, BigInt(value)).toString(2).padStart(width, '0');
}
export function fixedQR(A, b, {width = 24, fraction = 14, iterations = 14} = {}) {
  if (![8,14,18].includes(fraction) || width !== 24 || ![8,14,18].includes(iterations)) throw Error('Unsupported fixed-point format');
  if (A.length !== 3 || A.some(r => r.length !== 3) || b.length !== 3 || [...A.flat(), ...b].some(v => !Number.isFinite(v))) throw Error('Enter a finite 3 × 3 matrix and vector.');
  const scale = 2 ** fraction, S = BigInt(scale), limit = 1n << BigInt(width - 1);
  const fit = v => { if (v < -limit || v >= limit) throw Error('24-bit overflow. Reduce the inputs or choose fewer fractional bits.'); return v; };
  const quant = v => fit(BigInt(Math.sign(v) * Math.floor(Math.abs(v) * scale + .5)));
  const value = v => Number(v) / scale;
  const M = A.map((r,i) => [...r, b[i]].map(quant));
  const trace = [], solutions = [null, null, null];
  const snapshot = (kind, title, detail = {}) => {
    trace.push({kind, title, M: M.map(r => [...r]), solutions: [...solutions], ...detail});
  };
  const gain = Array.from({length:iterations}, (_,k) => Math.sqrt(1 + 2 ** (-2*k))).reduce((a,b) => a*b, 1);
  const gainWord = quant(1/gain);
  snapshot('intro', 'A linear system becomes a stream of words');
  let rotation = 0;
  for (let col = 0; col < 2; col++) for (let row = 2; row > col; row--) {
    const upper = row - 1;
    const pairs = Array.from({length:4-col}, (_,j) => ({column:j+col,x:M[upper][j+col],y:M[row][j+col]}));
    const context = {rotation, col, row, upper};
    snapshot('load', `Rotation ${rotation+1}: eliminate a${row+1}${col+1}`, {...context, pairs: pairs.map(p=>({...p}))});
    if (pairs[0].x === 0n && pairs[0].y === 0n) {
      snapshot('commit', 'Zero pivot pair: bypass this rotation', {...context,pairs:pairs.map(p=>({...p})),dropped:0n});
      rotation++; continue;
    }
    let angle = 0n;
    if (pairs[0].x < 0n) {
      pairs.forEach(p => {p.x=fit(-p.x);p.y=fit(-p.y);});
      angle = quant(Math.PI);
      snapshot('quadrant', 'Coarse rotation: negate both rows', {...context,pairs:pairs.map(p=>({...p})),angle});
    }
    const trail = [[value(pairs[0].x),value(pairs[0].y)]];
    for (let k=0;k<iterations;k++) {
      const d = pairs[0].y >= 0n ? 1n : -1n;
      const before = pairs.map(p=>({...p}));
      const lanes = before.map(p=>({...p,sx:p.x >> BigInt(k),sy:p.y >> BigInt(k)}));
      lanes.forEach(p=>{p.nx=fit(p.x+d*p.sy);p.ny=fit(p.y-d*p.sx);});
      const nextAngle=angle+d*quant(Math.atan(2**(-k)));
      const step={...context,k,d:Number(d),angle,nextAngle,lanes,trail:trail.map(p=>[...p])};
      snapshot('shift', `k = ${k}: arithmetic right shift`, step);
      snapshot('add', `k = ${k}: signed add / subtract`, step);
      lanes.forEach((p,j)=>{pairs[j].x=p.nx;pairs[j].y=p.ny;});
      angle=nextAngle;trail.push([value(pairs[0].x),value(pairs[0].y)]);
      snapshot('latch', `k = ${k}: latch the next register state`, {...step,angle,trail:trail.map(p=>[...p])});
    }
    const lanes=pairs.map(p=>({...p,px:p.x*gainWord,py:p.y*gainWord,nx:fit(roundDiv(p.x*gainWord,S)),ny:fit(roundDiv(p.y*gainWord,S))}));
    snapshot('gain','Remove the CORDIC gain', {...context,lanes,gain,gainWord,trail});
    lanes.forEach(p=>{M[upper][p.column]=p.nx;M[row][p.column]=p.ny;});
    const dropped=M[row][col];M[row][col]=0n;
    snapshot('commit','Write the rotated rows into R and c', {...context,lanes,dropped,trail});
    rotation++;
  }
  snapshot('triangular','QR complete: solve Rx = c');
  // A small diagonal is not a trustworthy divisor at this chosen resolution.
  if(M.some((r,i)=>r[i] <= 8n && r[i] >= -8n)) {
    snapshot('singular','A diagonal is too small for a reliable solve');
    return {trace,width,fraction,iterations,scale,gain,gainWord,M,solutions,singular:true};
  }
  for(let row=2;row>=0;row--) {
    let acc=0n;
    snapshot('back-load',`Back-substitution: row ${row+1}`,{row,acc});
    for(let j=row+1;j<3;j++) {
      const a=M[row][j], x=solutions[j], product=a*x, term=fit(roundDiv(product,S));
      snapshot('back-mul',`Multiply r${row+1}${j+1} · x${j+1}`,{row,j,a,x,product,term,acc});
      const next=fit(acc+term);
      snapshot('back-acc',`Accumulate the contribution of x${j+1}`,{row,j,a,x,product,term,acc,next});
      acc=next;
    }
    const numerator=fit(M[row][3]-acc), divisor=M[row][row];
    snapshot('back-sub',`Subtract known terms from c${row+1}`,{row,acc,numerator,divisor});
    const dividend=numerator*S, quotient=fit(roundDiv(dividend,divisor));
    snapshot('back-div',`Divide by r${row+1}${row+1}`,{row,acc,numerator,divisor,dividend,quotient});
    solutions[row]=quotient;
    snapshot('back-store',`Store x${row+1} and feed it to earlier rows`,{row,acc,numerator,divisor,quotient});
  }
  const x=solutions.map(value),residual=Math.hypot(...A.map((r,i)=>r.reduce((s,a,j)=>s+a*x[j],0)-b[i]));
  snapshot('done','The solution returns to the original system',{residual});
  return {trace,width,fraction,iterations,scale,gain,gainWord,M,solutions,x,residual,singular:false};
}
