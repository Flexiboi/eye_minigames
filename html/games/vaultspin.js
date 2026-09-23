MG.register('vaultspin', {
    title: 'Vault Spin',
    hint: 'Drag the dial to bring each lit number under the top marker, then release',
    run(api) {
        const diff = Math.max(1, Math.min(5, api.cfg.difficulty || 2));
        const tumblers = api.cfg.tumblers || (2 + Math.floor(diff / 2));
        const segments = 40;
        const tolSeg = diff <= 2 ? 1 : 0;

        const W = 320, H = 300;
        const cvs = document.createElement('canvas');
        cvs.width = W; cvs.height = H;
        cvs.style.cursor = 'grab';
        api.board.appendChild(cvs);
        const ctx = cvs.getContext('2d');
        const cxp = W / 2, cyp = H / 2, R = 110;

        const css = getComputedStyle(document.documentElement);
        const acc = (css.getPropertyValue('--accent') || '#00e0b8').trim();
        const suc = (css.getPropertyValue('--success') || '#39d98a').trim();

        const targets = [];
        for (let i = 0; i < tumblers; i++) targets.push(api.randInt(0, segments - 1));
        let step = 0, angle = 0, dragging = false, lastA = 0, done = false;

        function numToAngle(n) { return (n / segments) * Math.PI * 2 - Math.PI / 2; }
        function currentNum() {
            let n = Math.round(-angle / (Math.PI * 2) * segments) % segments;
            if (n < 0) n += segments;
            return n;
        }
        function segDiff(a, b) { const d = Math.abs(a - b) % segments; return Math.min(d, segments - d); }
        function dotState() {
            const st = [];
            for (let i = 0; i < tumblers; i++) st[i] = i < step ? 'done' : (i === step ? 'active' : '');
            return st;
        }
        function tag() { api.setTag(done ? 'CRACKED' : ('TUMBLER ' + (step + 1) + '/' + tumblers)); }
        api.setDots(tumblers, dotState());
        tag();

        function pointerAngle(e) {
            const b = cvs.getBoundingClientRect();
            const px = (e.clientX - b.left) * (cvs.width / b.width);
            const py = (e.clientY - b.top) * (cvs.height / b.height);
            return Math.atan2(py - cyp, px - cxp);
        }
        cvs.addEventListener('mousedown', (e) => { if (done) return; dragging = true; lastA = pointerAngle(e); cvs.style.cursor = 'grabbing'; });
        cvs.addEventListener('mousemove', (e) => {
            if (!dragging) return;
            const a = pointerAngle(e);
            let d = a - lastA;
            if (d > Math.PI) d -= Math.PI * 2;
            if (d < -Math.PI) d += Math.PI * 2;
            angle += d; lastA = a;
        });
        window.addEventListener('mouseup', upH);
        function upH() {
            if (!dragging || done) return;
            dragging = false; cvs.style.cursor = 'grab';
            if (segDiff(currentNum(), targets[step]) <= tolSeg) {
                step++; api.sfx('latch');
                api.setDots(tumblers, dotState());
                if (step >= tumblers) { done = true; api.stopTimer(); cleanup(); tag(); setTimeout(() => api.succeed(), 280); return; }
                tag();
            } else {
                api.shake();
            }
        }
        function cleanup() { window.removeEventListener('mouseup', upH); }

        api.startTimer(Math.max(14, 30 - diff * 2), () => { if (!done) { done = true; cleanup(); api.fail(); } });

        function draw() {
            ctx.clearRect(0, 0, W, H);
            const cur = currentNum();
            const tgt = done ? -1 : targets[step];
            const onTarget = !done && segDiff(cur, tgt) <= tolSeg;

            ctx.strokeStyle = 'rgba(255,255,255,0.12)'; ctx.lineWidth = 2;
            ctx.beginPath(); ctx.arc(cxp, cyp, R + 14, 0, Math.PI * 2); ctx.stroke();

            for (let i = 0; i < segments; i++) {
                const a = numToAngle(i) + angle;
                const big = i % 5 === 0;
                const isTgt = i === tgt;
                ctx.strokeStyle = isTgt ? acc : 'rgba(255,255,255,0.25)';
                ctx.lineWidth = isTgt ? 3 : (big ? 2 : 1);
                if (isTgt) { ctx.shadowColor = acc; ctx.shadowBlur = 12; }
                ctx.beginPath();
                ctx.moveTo(cxp + Math.cos(a) * (R + 10), cyp + Math.sin(a) * (R + 10));
                ctx.lineTo(cxp + Math.cos(a) * (R + (big ? -2 : 3)), cyp + Math.sin(a) * (R + (big ? -2 : 3)));
                ctx.stroke(); ctx.shadowBlur = 0;
                if (big || isTgt) {
                    ctx.fillStyle = isTgt ? acc : 'rgba(255,255,255,0.45)';
                    ctx.font = (isTgt ? 'bold 12px ' : '10px ') + 'monospace';
                    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
                    ctx.fillText(i, cxp + Math.cos(a) * (R - 14), cyp + Math.sin(a) * (R - 14));
                }
            }

            const g = ctx.createRadialGradient(cxp, cyp, 8, cxp, cyp, R - 26);
            g.addColorStop(0, '#1a2230'); g.addColorStop(1, '#0a0e14');
            ctx.fillStyle = g; ctx.beginPath(); ctx.arc(cxp, cyp, R - 26, 0, Math.PI * 2); ctx.fill();
            ctx.strokeStyle = onTarget ? suc : acc; ctx.lineWidth = 2; ctx.stroke();

            ctx.save(); ctx.translate(cxp, cyp); ctx.rotate(angle);
            ctx.strokeStyle = 'rgba(255,255,255,0.18)'; ctx.lineWidth = 3;
            for (let i = 0; i < 8; i++) {
                const a = i * Math.PI / 4;
                ctx.beginPath();
                ctx.moveTo(Math.cos(a) * (R - 44), Math.sin(a) * (R - 44));
                ctx.lineTo(Math.cos(a) * (R - 31), Math.sin(a) * (R - 31));
                ctx.stroke();
            }
            ctx.restore();

            ctx.fillStyle = onTarget ? suc : '#fff';
            if (onTarget) { ctx.shadowColor = suc; ctx.shadowBlur = 12; }
            ctx.beginPath(); ctx.moveTo(cxp, cyp - R - 4); ctx.lineTo(cxp - 8, cyp - R - 20); ctx.lineTo(cxp + 8, cyp - R - 20); ctx.closePath(); ctx.fill();
            ctx.shadowBlur = 0;

            ctx.fillStyle = onTarget ? suc : '#fff'; ctx.font = 'bold 30px monospace';
            ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
            ctx.fillText(cur, cxp, cyp - 6);
            if (!done) {
                ctx.fillStyle = 'rgba(255,255,255,0.5)'; ctx.font = '11px monospace';
                ctx.fillText('find ' + tgt, cxp, cyp + 20);
            }

            loop = requestAnimationFrame(draw);
        }
        let loop = requestAnimationFrame(draw);
        return { destroy() { cancelAnimationFrame(loop); cleanup(); } };
    }
});
