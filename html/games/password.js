MG.register('password', {
    title: 'Password',
    hint: 'enter the exact password to unlock',
    run(api) {
        const rawPassword = api.cfg.password;
        const password = rawPassword == null ? '' : String(rawPassword);
        const caseSensitive = api.cfg.caseSensitive !== false;
        const attempts = Math.max(1, Number(api.cfg.attempts) || 3);
        const diff = Math.max(1, Math.min(5, Number(api.cfg.difficulty) || 2));

        let tries = 0;
        let ended = false;

        const box = document.createElement('div');
        box.style.cssText = 'width:min(520px,90vw);display:flex;flex-direction:column;gap:14px;';
        box.innerHTML = `
            <div class="label">PASSWORD REQUIRED</div>
            <div style="font-size:13px;color:var(--muted);line-height:1.5;">
                Enter the password configured by the script. ${caseSensitive ? 'Capitalization matters.' : 'Capitalization does not matter.'}
            </div>
            <div style="display:flex;gap:8px;align-items:center;">
                <input id="passwordInput" type="password" autocomplete="off" spellcheck="false"
                    style="flex:1;height:46px;padding:0 14px;border:1px solid var(--line);border-radius:6px;
                    background:var(--panel);color:var(--text);font-family:var(--mono);font-size:18px;outline:none;"
                    placeholder="Enter password">
                <button id="submitBtn" class="btn" style="height:46px;padding:0 18px;">UNLOCK</button>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;font-family:var(--mono);font-size:12px;">
                <span id="status" style="color:var(--muted);">ATTEMPTS ${attempts}</span>
                <span id="feedback" style="color:var(--muted);"></span>
            </div>`;
        api.board.appendChild(box);

        const input = box.querySelector('#passwordInput');
        const submitBtn = box.querySelector('#submitBtn');
        const status = box.querySelector('#status');
        const feedback = box.querySelector('#feedback');

        function normalize(value) {
            value = String(value == null ? '' : value);
            return caseSensitive ? value : value.toLowerCase();
        }

        function updateStatus() {
            status.textContent = `ATTEMPTS ${Math.max(0, attempts - tries)}`;
        }

        function submit() {
            if (ended) return;
            const entered = input.value;
            if (!entered.length) {
                api.shake();
                feedback.style.color = 'var(--danger)';
                feedback.textContent = 'ENTER PASSWORD';
                return;
            }

            tries++;
            if (normalize(entered) === normalize(password)) {
                ended = true;
                api.stopTimer();
                feedback.style.color = 'var(--accent)';
                feedback.textContent = 'ACCESS GRANTED';
                input.disabled = true;
                submitBtn.disabled = true;
                api.setTag('UNLOCKED');
                api.sfx('success');
                setTimeout(() => api.succeed(), 300);
                return;
            }

            updateStatus();
            input.value = '';
            api.shake();
            api.sfx('error');
            feedback.style.color = 'var(--danger)';
            feedback.textContent = 'INVALID PASSWORD';

            if (tries >= attempts) {
                ended = true;
                api.stopTimer();
                input.disabled = true;
                submitBtn.disabled = true;
                api.setTag('LOCKED');
                setTimeout(() => api.fail(), 600);
                return;
            }

            api.setTag(`ATTEMPT ${tries + 1}/${attempts}`);
        }

        submitBtn.addEventListener('click', submit);

        // Normal NUI input and world-space DUI input use the same editor.
        // For world DUI, keyboard events arrive through the NUI capture page
        // and are dispatched onto the DUI document, so there is no native
        // browser text input to mutate the field automatically.  Handle the
        // editing keys explicitly here.
        function handleDuiKey(e) {
            if (ended || input.disabled) return;

            // Ignore key events that originated from the password field itself;
            // those already use the browser's native editing behavior.
            if (e.target === input || e.target === submitBtn) return;

            if (e.key === 'Enter') {
                e.preventDefault();
                submit();
                return;
            }

            if (e.key === 'Backspace') {
                e.preventDefault();
                const start = input.selectionStart == null ? input.value.length : input.selectionStart;
                const end = input.selectionEnd == null ? input.value.length : input.selectionEnd;
                if (start !== end) {
                    input.setRangeText('', start, end, 'end');
                } else if (start > 0) {
                    input.setRangeText('', start - 1, start, 'end');
                }
                return;
            }

            if (e.key === 'Delete') {
                e.preventDefault();
                const start = input.selectionStart == null ? input.value.length : input.selectionStart;
                const end = input.selectionEnd == null ? input.value.length : input.selectionEnd;
                if (start !== end) {
                    input.setRangeText('', start, end, 'end');
                } else if (start < input.value.length) {
                    input.setRangeText('', start, start + 1, 'end');
                }
                return;
            }

            if (e.key === 'ArrowLeft' || e.key === 'ArrowRight' ||
                e.key === 'Home' || e.key === 'End') {
                e.preventDefault();

                let pos = input.selectionStart == null ? input.value.length : input.selectionStart;
                if (e.key === 'ArrowLeft') pos = Math.max(0, pos - 1);
                else if (e.key === 'ArrowRight') pos = Math.min(input.value.length, pos + 1);
                else if (e.key === 'Home') pos = 0;
                else if (e.key === 'End') pos = input.value.length;

                input.setSelectionRange(pos, pos);
                return;
            }

            // Only insert printable characters. Ignore modifiers/function keys.
            if (typeof e.key === 'string' && e.key.length === 1 &&
                !e.ctrlKey && !e.altKey && !e.metaKey) {
                e.preventDefault();

                const start = input.selectionStart == null ? input.value.length : input.selectionStart;
                const end = input.selectionEnd == null ? input.value.length : input.selectionEnd;

                input.setRangeText(e.key, start, end, 'end');
                input.dispatchEvent(new Event('input', { bubbles: true }));
            }
        }

        document.addEventListener('keydown', handleDuiKey, true);

        input.addEventListener('keydown', (e) => {
            // Native NUI mode: let the browser handle normal editing, but
            // retain the Enter-to-submit behavior.
            if (e.key === 'Enter') {
                e.preventDefault();
                submit();
            }
        });

        updateStatus();
        api.setTag(`ATTEMPT 1/${attempts}`);
        api.startTimer(Math.max(15, 45 - diff * 5), () => {
            if (!ended) {
                ended = true;
                input.disabled = true;
                submitBtn.disabled = true;
                api.fail();
            }
        });

        // Only focus the field in normal NUI.  In DUI mode, the NUI capture
        // input must keep focus so GTA keyboard events continue to reach Lua.
        if (!api.cfg.duiController) {
            setTimeout(() => input.focus(), 0);
        }

        return {
            destroy() {
                document.removeEventListener('keydown', handleDuiKey, true);
            }
        };
    }
});
