// Update dynamic rules for declarativeNetRequest based on saved settings
async function updateRedirectRules() {
  const { rules = [] } = await chrome.storage.local.get("rules");
  
  // Filter for automatic redirect rules only
  const dynamicRules = rules
    .filter(r => r.active && r.mode === "auto")
    .map((r, index) => ({
      id: index + 1,
      priority: 1,
      action: {
        type: "redirect",
        redirect: { regexSubstitution: r.replaceRegex }
      },
      condition: {
        regexFilter: r.matchRegex,
        resourceTypes: ["main_frame"]
      }
    }));

  const oldRules = await chrome.declarativeNetRequest.getDynamicRules();
  const oldRuleIds = oldRules.map(r => r.id);

  await chrome.declarativeNetRequest.updateDynamicRules({
    removeRuleIds: oldRuleIds,
    addRules: dynamicRules
  });
}

// Handle manual trigger (clicking the extension icon)
chrome.action.onClicked.addListener(async (tab) => {
  const { rules = [] } = await chrome.storage.local.get("rules");
  const manualRules = rules.filter(r => r.active && r.mode === "manual");

  for (const rule of manualRules) {
    const regex = new RegExp(rule.matchRegex);
    if (regex.test(tab.url)) {
      const newUrl = tab.url.replace(regex, rule.replaceRegex);
      chrome.tabs.create({ url: newUrl });
      return; // Stop after first match
    }
  }
});

// Listen for storage changes to refresh rules
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.rules) {
    updateRedirectRules();
  }
});

// Initialize rules on install
chrome.runtime.onInstalled.addListener(updateRedirectRules);
chrome.runtime.onStartup.addListener(updateRedirectRules);