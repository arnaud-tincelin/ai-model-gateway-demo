# AI Model Gateway Demo

Deploy Azure AI Foundry agents that route through Azure API Management for centralized governance, monitoring, and cost control.

Detailed Walkthrough available on [Medium](https://medium.com/@arnaud.tincelin/expose-models-on-microsoft-foundry-through-your-own-ai-gateway-a-practical-end-to-end-walkthrough-c65615106bfe)

## Architecture

```
Azure AI Agent → Microsoft Foundry Project → APIM Gateway Connection → APIM → Microsoft Foundry Project
```

## Reference Documentation

- [BYO AI Gateway](https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/ai-gateway)
- [APIM Connection Objects](https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/01-connections/apim/APIM-Connection-Objects.md)

