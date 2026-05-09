# Chrome-extension

A chrome extension for introducing custom behavior.

MVP will contain a contextual handler.

Custom rules can be introduced in the settings page, to either
1. Automatically redirect to a different url. which is generated based on rules. eg. open old.reddit.com rather than reddit.com, breezewiki.com instead of fandom.com.
2. Open a second tab with the generated url instead of redirecting in the current tab, on clicking the extension button.

The rewrite rule will be based on regex.
For each entry in the settings page, a check box would choose between automatic redirect in current tab, and manually opening the rewritten link in a new tab.
