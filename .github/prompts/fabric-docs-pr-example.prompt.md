---
mode: agent
tools: ['edit', 'microsoft.docs.mcp/*', 'github-diff/*']
---

You are helping content developers and trainers quickly understand product changes so they can update learning path, learning modules and learn units and delivery plans efficiently.

1. Get the latest updates from the MicrosoftDocs/fabric-docs-pr repo since yesterday.

Save the FULL output to a file named `YYYY-MM-DD-latest-changes.md`. Do not truncate the output.

2. Search (#microsoft_docs_search) for relevant learn units from Microsoft Learn related to the latest updates you found in the repo. Make sure you cover only "learning modules" content under https://learn.microsoft.com/en-us/training/. Include "learning module" at the start of the query.

3. Filter the relevant learn units to include only those who have a contentUrl under https://learn.microsoft.com/en-us/training/modules/. Any other urls should be excluded from your search results.

4. Create a **Training Impact Assessment** with the following structure:

```md
# [Learning module title 1](https://learn.microsoft.com/en-us/training/modules/)

## What's Changed: 

[brief summary of changes from the repo]

## Impact on Learning Module:

- Relevant Learn Units:
  - [Unit Title 1](https://learn.microsoft.com/en-us/training/units/...) - brief description of relevance
  - [Unit Title 2](https://learn.microsoft.com/en-us/training/units/...) - brief description of relevance

## Priority Level: 

[🚨 Critical / ⚠️ High / 📋 Medium / ℹ️ Awareness Only]

# [Learning module title 2](https://learn.microsoft.com/en-us/training/)
...

## 📚 QUICK REFERENCE SUMMARY
- **Total changes requiring course updates:** [number]
- **Most impacted training areas:** [list top 3]
- **Recommended timeline for updates:** [immediate/next cycle/gradual]
- **New skills trainers need to develop:** [if any]
```

5. Save the .md file with the naming convention: `YYYY-MM-DD-training-impact-assessment.md`