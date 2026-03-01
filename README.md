# AI Model Gateway Demo

Deploy Azure AI Foundry agents that route through Azure API Management for centralized governance, monitoring, and cost control.

Detailed Walkthrough available on [Medium](https://medium.com/@arnaud.tincelin/expose-models-on-microsoft-foundry-through-your-own-ai-gateway-a-practical-end-to-end-walkthrough-c65615106bfe)

## Architecture

```
Azure AI Agent → Microsoft Foundry Project → APIM Gateway Connection → APIM → Microsoft Foundry Project
```

## GitHub Issue Management

This repository includes a tool to create GitHub issues from markdown files stored in the `issues/` folder.

### Usage

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Create issue files in the `issues/` folder using the format described in [issues/README.md](issues/README.md)

3. Run the script to create issues:
   ```bash
   # Set your GitHub token
   export GITHUB_TOKEN=your_github_token
   
   # Create issues from all files in issues/ folder
   python scripts/create_issues.py
   
   # Or create from specific files
   python scripts/create_issues.py issues/my-issue.md
   
   # Dry run to see what would be created
   python scripts/create_issues.py --dry-run
   ```

See [issues/README.md](issues/README.md) for the issue file format and more details.

## Reference Documentation

- [BYO AI Gateway](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/ai-gateway)
- [APIM Connection Objects](https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/01-connections/apim/APIM-Connection-Objects.md)

