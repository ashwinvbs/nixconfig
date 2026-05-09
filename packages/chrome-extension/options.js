const container = document.getElementById('rules-container');
const template = document.getElementById('rule-template');

function createRuleRow(data = { active: true, matchRegex: '', replaceRegex: '', mode: 'auto' }) {
  const clone = template.content.cloneNode(true);
  const row = clone.querySelector('.rule-row');
  
  row.querySelector('.rule-active').checked = data.active;
  row.querySelector('.rule-match').value = data.matchRegex;
  row.querySelector('.rule-replace').value = data.replaceRegex;
  row.querySelector('.rule-mode').value = data.mode;
  
  row.querySelector('.remove-rule').onclick = () => row.remove();
  container.appendChild(clone);
}

async function loadRules() {
  const { rules = [] } = await chrome.storage.local.get('rules');
  rules.forEach(createRuleRow);
  if (rules.length === 0) createRuleRow();
}

async function saveRules() {
  const rows = container.querySelectorAll('.rule-row');
  const rules = Array.from(rows).map(row => ({
    active: row.querySelector('.rule-active').checked,
    matchRegex: row.querySelector('.rule-match').value,
    replaceRegex: row.querySelector('.rule-replace').value,
    mode: row.querySelector('.rule-mode').value
  })).filter(r => r.matchRegex);

  await chrome.storage.local.set({ rules });
  alert('Settings saved!');
}

document.getElementById('add-rule').onclick = () => createRuleRow();
document.getElementById('save-rules').onclick = saveRules;

loadRules();