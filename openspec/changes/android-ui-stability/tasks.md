## 1. Adaptive Foundation

- [x] 1.1 Add lightweight mobile adaptive heuristics for compact width, short height, and large text conditions
- [x] 1.2 Apply the shared adaptive rules to high-risk mobile widgets without changing business logic

## 2. Transaction And Home Stability

- [x] 2.1 Refactor `TransactionCard` to support a narrow-screen fallback layout that preserves readability
- [x] 2.2 Adjust `Navbar` and home floating actions to avoid overlap with content and bottom safe areas
- [x] 2.3 Update `HeroCard` and `HomeScreen` spacing/text behavior for compact Android devices

## 3. AI Screen Stability

- [x] 3.1 Add compact-density behavior to `AIInputScreen` header, quick actions, and composer
- [x] 3.2 Ensure AI screen content remains accessible with large text and keyboard insets on Android

## 4. Verification

- [ ] 4.1 Verify key mobile screens on representative narrow and short Android viewport sizes
- [ ] 4.2 Verify transaction cards, bottom navigation, and floating actions no longer collide on compact Android screens
- [ ] 4.3 Verify AI input remains usable on compact Android devices without obscured controls
