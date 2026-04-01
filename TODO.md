# TODO

- [ ] Fix chatbot connection and response relevance
  - [x] Harden `lib/services/chatbot_service.dart` response parsing and error propagation
  - [x] Update `lib/screens/plant_assistant_screen.dart` to handle service errors consistently
  - [x] Avoid storing backend/technical error strings as normal assistant replies
  - [x] Run `dart format` on touched files
  - [x] Run analyzer/checks and fix any introduced issues

- [ ] Align prediction-result plant detail with catalogue detail UI
  - [ ] Update `lib/screens/prediction_result_screen.dart` to use `PlantDetailScreen` for predicted plant detail

- [ ] Enhance submit remedy screen UI/theme and copy
  - [ ] Update `lib/screens/submit_remedy_screen.dart` top heading to `Share Medicinal Plant Information`
  - [ ] Remove `Submit a Remedy` wording
  - [ ] Improve styling to match app theme

- [ ] Enhance condition remedies screen to follow app theme
  - [ ] Update `lib/screens/condition_remedies_screen.dart` visual hierarchy (header/loading/empty/cards)
