# StorePulse — Physical iPhone Testing Checklist

This checklist verifies all features of the application on your physical iPhone 18 Pro.

---

## 1. Initial Launch & Permissions
- [ ] Install and launch the app on your iPhone.
- [ ] Verify the iOS system notification permission dialog prompts: *"StorePulse would like to send you notifications"*.
- [ ] Tap **Allow**.
- [ ] Navigate to **Settings / Diagnostics** screen in the app.
- [ ] Check **Permission Status**: should display `authorized`.
- [ ] Inspect **Device ID**: confirm a persistent UUID is assigned.

---

## 2. In-App Dashboard & Instant Test
- [ ] On the **Dashboard**, tap **Send Test**.
- [ ] Verify the banner appears at the top of the iPhone screen with sound and haptics.
- [ ] Verify the notification card populates the **Live Lock-Screen Stack** section immediately.
- [ ] Verify the notification indicates the `SIMULATION` badge.

---

## 3. Automation Scheduler & Background Loop
- [ ] Navigate to the **Scheduler** tab:
  - Set **Min Interval** to `10` seconds.
  - Set **Max Interval** to `20` seconds.
  - Set **Max Per Hour** to `30`.
  - Tap **Save**.
- [ ] Return to the **Dashboard** and tap **Start**.
- [ ] Verify the status card transitions to **ACTIVE (AUTOMATING)** in vibrant emerald green.
- [ ] Watch the **Next Send** countdown timer tick down.
- [ ] When the countdown reaches `0`, verify that a new notification arrives.
- [ ] Tap **Pause**: verify automation halts and countdown disappears.
- [ ] Tap **Resume**: verify automation continues from the next randomized interval.
- [ ] Tap **Emergency Stop**: verify all jobs are immediately terminated and UI displays **EMERGENCY STOPPED**.

---

## 4. Templates & Variable Interpolation
- [ ] Navigate to the **Templates** tab.
- [ ] Tap the **+** (Add) button.
- [ ] Create a custom template:
  - Title: `Order #{{order_id}}`
  - Body: `{{amount}} paid via Express Checkout`
  - Weight: `50`
- [ ] Inspect the live preview card in the modal to ensure placeholder variables format cleanly.
- [ ] Save the template.
- [ ] Toggle off any existing templates and observe that only enabled templates are chosen.

---

## 5. History & Delivery Audit
- [ ] Navigate to the **History** tab.
- [ ] Verify that every sent notification is recorded with:
  - Timestamp.
  - Delivery status (`FCM Accepted (In Transit)` or `Confirmed Delivered`).
  - Server response code.
- [ ] Tap a history tile to expand its diagnostic drawer.
- [ ] Test the search bar by typing an order number or keyword.
- [ ] Filter by status (`FCM Submitted`, `Delivered`, `Rate Limited`).
