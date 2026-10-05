'use strict';
// Deliberately in-memory only: no network calls, logs or persistent report data.
const byId = id => document.getElementById(id);
const bodyField = byId('report-body');
function selectTab(history, focus = false) {
  for (const name of ['new', 'history']) {
    const active = history === (name === 'history');
    byId(name + '-tab').setAttribute('aria-selected', String(active));
    byId(name + '-tab').tabIndex = active ? 0 : -1;
    byId(name + '-panel').hidden = !active;
    if (active && focus) byId(name + '-tab').focus();
  }
}
byId('new-tab').onclick = () => selectTab(false);
byId('history-tab').onclick = () => selectTab(true);
byId('start-report').onclick = () => { selectTab(false); byId('destination').focus(); };
document.querySelector('[role=tablist]').onkeydown = event => {
  if (!['ArrowRight','ArrowLeft','Home','End'].includes(event.key)) return;
  event.preventDefault();
  selectTab(event.key === 'End' || (event.key !== 'Home' && document.activeElement === byId('new-tab')), true);
};
function update() {
  const offline = byId('offline').checked;
  const unavailable = byId('unavailable').checked;
  byId('destination').disabled = unavailable;
  byId('count').textContent = `${bodyField.value.length.toLocaleString()} / 5,000`;
  byId('submit').disabled = offline || unavailable || !byId('destination').value ||
      !byId('consent').checked || bodyField.value.trim().length < 20;
  byId('error').textContent = offline
    ? 'You are offline. Reconnect to submit. Your draft remains only while this page stays open.'
    : unavailable ? 'No reviewer destinations are available yet. Please try again later.' : '';
}
for (const id of ['destination','report-body','consent','offline','unavailable']) byId(id).addEventListener('input', update);
for (const id of ['light','large','solid']) byId(id).onchange = event => document.body.classList.toggle(id, event.target.checked);
byId('report-form').onsubmit = event => {
  event.preventDefault();
  update();
  if (byId('submit').disabled || !event.target.reportValidity()) return;
  byId('confirmation').showModal();
};
byId('close-dialog').onclick = () => byId('confirmation').close();
update();
