

#  TrackIt 2.0

### *main character mode: on ✨*

**A dark-mode-first Flutter productivity app that actually gets you.**  
Tasks. Notes. Journal. Expenses. Habits. Health. All in one place. Powered by Gemini AI.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-2.x-00BCD4?style=for-the-badge)
![Hive](https://img.shields.io/badge/Hive-offline--first-FF6F00?style=for-the-badge)
![Gemini](https://img.shields.io/badge/Gemini_AI-1.5_Flash-4285F4?style=for-the-badge&logo=google&logoColor=white)


---

## 🤔 What even is this?

Most productivity apps either look like a hospital form or cost ₹800/month. TrackIt 2.0 is neither.

It's a **fully offline-first Flutter app** that puts your tasks, notes, journal, expenses, habits, and health data in one beautifully designed dark interface — with a conversational AI assistant that actually reads your data instead of giving you generic advice like "drink more water."

Built from scratch. PRD to Play Store. One developer. Four weeks.

---

## ✨ Features that actually slap

### 📋 Tasks
- Create tasks with priority levels — Low 🟢 Medium 🟡 High 🟠 Urgent 🔴
- Due date + time with local push notifications that fire even when the app is closed
- Filter by All / Pending / Completed
- Swipe to delete, tap to complete
- AI-powered priority suggestions based on your deadlines

### 📝 Notes
- Masonry grid layout with color-coded labels
- Rich toolbar — **Bold**, _Italic_, • Bullet lists, ☐ Checkboxes
- Auto-continue bullet lists on Enter (because friction is the enemy)
- Pin important notes to top
- Full-text search
- View mode → Edit mode on tap

### 📔 Journal
- One entry per day, date-stamped
- **Smart mood check-in** — slider 1-10 + emotion chips (Tired, Money stress, Exams, People, Health...) + energy level
- Image attachments up to 3 per entry, stored locally
- **Guided prompts** — if you stare at a blank page for 8 seconds, a random prompt slides up from 30 curated questions
- **On This Day** memory — shows entries from 1 month or 1 year ago on the same date
- **AI weekly mood summary** — Gemini analyses your actual mood scores, emotion tags, and energy levels to write a warm, personal weekly reflection
- Mood graph (line chart) showing mood over the month with tap-to-entry navigation
- Word count, streak, and longest entry stats

### 💸 Expenses
- Add expenses with 9 built-in categories with emoji icons
- Monthly budget tracking with real-time balance
- **UPI SMS auto-detection** — reads bank debit SMS on screen open, auto-fills amount (works for HDFC, SBI, ICICI, AXIS and more)
- Pie chart + daily bar chart reports via `fl_chart`
- **AI expense reduction suggestions** — Gemini analyzes your actual spending by category and gives specific, non-generic tips
- Transaction history with category filters
- Swipe to delete + long press for options
- Over-budget warning banner

### 🔄 Habits
- Create daily or custom habits with emoji icons
- **Month calendar heatmap** — each day shows its date number, completed days are tinted in habit color, broken days stay unmarked — intuitive at a glance
- Current and longest streak tracking
- **Medication mode** — add up to 4 daily time-based reminders per habit, track each dose individually with "Dose not taken" alerts when time passes
- Weekly 7-day strip showing this week's progress
- Long press to edit or delete

### 🏃 Health
- **Live step counter** using device pedometer via `pedometer` package
- Automatic calorie calculation from steps (steps × 0.04)
- Manual workout logging with 8 quick-add presets (Walk, Run, Cycling, Gym, HIIT, Yoga, Swimming, Sports)
- Custom calorie entry for any workout
- Daily step goal with editable target (default 8,000)
- Progress bar that turns green when goal is hit 🎉

### 🏆 Badges (14 custom neon-illustrated achievements)

Grouped into 6 series:

| Series | Badges |
|--------|--------|
| 🟡 Starter | Day 1 Energy, First Task Done |
| 🔴 Consistency | Streak Beast (7 days), Unstoppable (30 days) |
| 🔵 Productivity | Task Slayer (10 tasks/week), Overachiever (all habits 7 days) |
| 🟣 Focus | Locked In (14 days straight), Monk Mode |
| ⚡ Gen Z | Consistent, Last Minute God, Fresh Start, Comeback Arc |
| 🟢 Module | Budget Buster, Dear Diary |

Locked badges shown in grayscale. Earned badges animate in with confetti overlay. Tap any badge for detail.

### ✨ TrackIt AI
- Conversational Gemini 1.5 Flash assistant on the dashboard
- Reads your **actual Hive data** — pending tasks, spending, habits, mood scores
- Quick suggestion chips: "How was my week?", "Where am I overspending?", "Which habit needs work?"
- Gen Z tone — talks like a smart friend, not a corporate chatbot
- Handles "I have no data yet" gracefully with encouragement

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/          # AppColors, AppSizes, AppStrings
│   ├── theme/              # Dark + light MaterialTheme
│   ├── router/             # GoRouter with ShellRoute bottom nav
│   ├── utils/              # AccountScope, NotificationService
│   └── widgets/            # Shared UI components
│
├── features/
│   ├── auth/               # Firebase Auth + local Hive cache
│   ├── onboarding/         # 4-screen flow: name/emoji → vibe → budget → ready
│   ├── dashboard/          # Home screen + TrackIt AI chat sheet
│   ├── tasks/              # Full CRUD + notifications + badge triggers
│   ├── notes/              # Rich text + color labels + search
│   ├── journal/            # Mood tracking + images + AI summary
│   ├── expenses/           # Budget tracking + charts + UPI SMS
│   ├── habits/             # Streaks + calendar + medication
│   ├── health/             # Pedometer + calorie tracking
│   └── badges/             # 14 badges + celebration overlay
│
└── shared/
    ├── ai_service.dart     # All Gemini API calls with gen z personality
    └── upi_sms_service.dart # SMS inbox scanner + live listener
```

---

## 🛠️ Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| **Framework** | Flutter 3.x + Dart 3.x | Cross-platform, fast, beautiful |
| **State Management** | Riverpod 2.x | `StateNotifierProvider`, `Provider.family`, reactive rebuilds |
| **Local Database** | Hive Flutter | Offline-first, fast reads, TypeAdapters |
| **Navigation** | GoRouter 14.x | ShellRoute for bottom nav, deep linking |
| **Auth** | Firebase Auth | Email/password with local Hive caching |
| **AI** | Google Gemini 1.5 Flash | Conversational, expense suggestions, mood summaries |
| **Charts** | fl_chart | Pie, bar, line charts for expenses and habits |
| **Notifications** | flutter_local_notifications | Scheduled task reminders, daily habit alerts |
| **Step Tracking** | pedometer | Device sensor integration |
| **SMS Reading** | telephony | UPI transaction auto-detection |
| **PDF Export** | pdf + printing | Monthly expense reports |
| **Fonts** | google_fonts (Inter) | Clean, modern, readable |

---

## 🎨 Design System

```dart
// Module colors — each section has its own identity
tasks    = #378ADD  // Blue — focus, clarity
notes    = #7F77DD  // Purple — creative, calm
journal  = #9B6210  // Amber — warm, personal
expenses = #1D9E75  // Teal — money, growth
habits   = #06B6D4  // Cyan — fresh, energetic

// Dark backgrounds
background    = #0F0F0F
surface       = #1A1A1A
surfaceVariant = #222222
border        = #333333

// Badge system
badgeBg       = #0F172A  // Deep navy — makes neon glow pop
```

All module colors appear **only** on icons, active states, tags and indicators. Backgrounds always stay dark. Color coding means users instinctively know where they are in the app without reading labels.

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x SDK
- Android Studio / VS Code
- A Gemini API key from [aistudio.google.com](https://aistudio.google.com)
- Firebase project (for auth)

### Setup

```bash
# Clone the repo
git clone https://github.com/yourusername/trackit.git
cd trackit

# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Create .vscode/launch.json with your Gemini key
```

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "TrackIt",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=GEMINI_KEY=your_key_here"]
    }
  ]
}
```

```bash
# Connect Firebase
flutterfire configure

# Run (press F5 in VS Code or)
flutter run --dart-define=GEMINI_KEY=your_key_here
```

### Android Permissions

Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_SMS"/>
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.BODY_SENSORS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

---

## 📱 Screens

| Screen | Description |
|--------|-------------|
| Splash | Animated fade-in, routes based on auth + onboarding state |
| Auth | Login/Signup toggle in single card, Firebase email/password |
| Onboarding (×4) | Name + emoji → Vibe question → Budget → All set |
| Dashboard | Module summary cards + health + habits + AI chat + badges |
| Tasks | Filterable list with priority tags + swipe gestures |
| Notes | Masonry grid with rich text editor |
| Journal | Entry list with mood graph + On This Day + guided prompts |
| Expenses | Balance cards + recent transactions + UPI detection |
| Expense Report | Pie + bar charts + AI insights + PDF export |
| Habits | Weekly strip + habit cards with expandable month calendar |
| Habit Detail | Full heatmap + streak stats + line chart |
| Badges | 14 badges in 6 series, earned full-color, locked grayscale |
| Profile | User stats + earned badges + settings + edit profile |

---

## 🧠 The AI bit (actually impressive)

TrackIt AI isn't just a chatbot slapped on top. It has context:

```dart
// What Gemini actually receives per request
Map<String, dynamic> appData = {
  'pendingTasks': 3,
  'completedThisWeek': 12,
  'monthlyBudget': 8000,
  'monthlySpent': 21000,        // yes it knows you overspent 💀
  'topCategory': 'Clothing',
  'habitCount': 4,
  'bestStreak': 9,
  'journalCount': 5,
  'avgMood': '6.4',             // from actual 1-10 slider data
};
```

The mood summary prompt includes day-by-day emotion tags and energy levels, not just emoji labels. Gemini gets real signals like "Thursday: mood 3/10, energy Low, tags: Exams, Money stress" — so the summary is actually useful.

---

## 🏅 Badge System Deep Dive

Badges are stored in Hive as boolean flags scoped to the current user's email. Each trigger point in the app calls `BadgeService.checkAndAward()`:

```dart
// When a task is completed
await badgeService.checkAndAward('task_completed', {
  'totalCompleted': 1,       // First Task Done 🚀
  'completedThisWeek': 10,   // Task Slayer ⚔️
  'isOnDueDate': true,       // Last Minute God 😭 (×3)
});

// When a journal entry is saved
await badgeService.checkAndAward('journal_written', {});
// → Dear Diary 📔 (first time only)

// On every app open
await badgeService.checkAndAward('app_opened', {});
// → Day 1 Energy ⚡ (first ever)
// → Fresh Start 🌿 (after 2+ days away)
// → Locked In 🎧 (14 consecutive days)
```

---

## 🔐 Data & Privacy

- **Offline-first** — all data lives in Hive on your device
- **User-scoped keys** — every Hive key is prefixed with the user's email hash, so multiple accounts on one device don't bleed data into each other
- **No ads, no tracking, no cloud sync** (yet)
- Firebase is used only for authentication — zero user data sent to Firestore
- Gemini API calls contain only anonymized aggregate data (counts and averages, never raw note/journal content)

---

## 🗺️ What's next (v3 wishlist)

- [ ] Firebase Firestore sync — data across devices
- [ ] Google Sign-In
- [ ] PhonePe push notification parsing (SMS isn't enough anymore tbh)
- [ ] Widget support — home screen habit checkboxes
- [ ] PDF journal export
- [ ] Shared habits with accountability partner
- [ ] Cross-module AI insights ("you spend more on food when your mood is low")
- [ ] Apple Health / Google Fit integration for better step accuracy

---

## 👩‍💻 Built by

**Sanikaa Lamkhade**  
Flutter Developer · CS Student · Pune, India

> *"Built this from a PRD, to 26 Figma screens, to a Play Store app. Every line of code taught me something."*

---

## 📄 License

MIT License — do whatever you want, just don't claim you built it from scratch 😭

---

<div align="center">

**If this README convinced you the app is good, imagine actually using it.**

⭐ Star the repo · 🐛 Report issues · 🍴 Fork and build something cool

*Made with 💙 Flutter, too much chai ☕, and Gemini AI*

