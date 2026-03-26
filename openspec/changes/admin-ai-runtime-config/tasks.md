## 1. Runtime Config Data Model

- [x] 1.1 Add repository support for loading draft and published `ai_runtime_config` documents from `system_configs`
- [x] 1.2 Add repository methods for saving draft runtime config, publishing runtime config, and writing admin audit logs
- [x] 1.3 Define default runtime AI config values, including AI mode, provider/model, fallback policy, image strategy, and four prompt layers

## 2. Admin Web AI Config UX

- [x] 2.1 Extend `AiConfigPage` with a separate “Real AI Runtime Config” section without regressing the existing local lexicon workflow
- [x] 2.2 Add draft/publish controls for runtime AI config that mirror the existing lexicon safety model
- [x] 2.3 Add structured editors for `rolePrompt`, `taskPrompt`, `cardRulesPrompt`, and `conversationRulesPrompt`
- [x] 2.4 Add masked API key editing and persistence behavior suitable for direct runtime key management
- [x] 2.5 Add preview behavior for runtime AI config that clearly indicates whether preview is using draft settings

## 3. App-Side Runtime AI Behavior

- [x] 3.1 Add application-side loading of published runtime AI config and gate real AI behavior on the published AI mode setting
- [x] 3.2 Implement effective prompt assembly from the four stored prompt layers in deterministic order
- [x] 3.3 Extend AI processing flow so AI mode can return clarification, natural reply, or confirmation-card-ready output without breaking existing save UI
- [x] 3.4 Apply the same clarification-or-card contract to image-driven AI interactions as to text-driven interactions
- [x] 3.5 Preserve local parse as the stable non-AI path when AI mode is off or runtime AI is not usable

## 4. Verification and Rollout Safety

- [x] 4.1 Verify that admin web AI config changes do not break existing lexicon editing, preview, or publish workflows
- [x] 4.2 Verify that runtime AI responses only create cards when transaction data is sufficiently complete
- [x] 4.3 Verify that broad conversational messages can receive natural replies without fabricated transaction cards
- [x] 4.4 Verify rollback behavior by disabling AI mode or reverting to a previous published runtime config
