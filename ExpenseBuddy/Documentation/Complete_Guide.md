# 🚀 The Complete Guide to ExpenseBuddy

Welcome to **ExpenseBuddy** — a beautiful iOS app that makes splitting expenses with friends easy and stress-free. Think of it like **Splitwise**, built with **SwiftUI** and powered by **Firebase**.

---

## 1. What Does ExpenseBuddy Do?

Imagine you go on a trip with 3 friends. One person pays for the hotel, another for food, another for the taxi. At the end, nobody knows who owes what. **ExpenseBuddy solves this.** You just tell the app who paid what, and it figures out the rest.

```mermaid
flowchart LR
    A["🍕 You pay ₹600 for Pizza"] --> App["📱 ExpenseBuddy"]
    B["🏨 Bob pays ₹3000 for Hotel"] --> App
    C["🚕 Charlie pays ₹900 for Taxi"] --> App
    App --> Result["✅ App tells everyone\nwho owes who!"]
```

---

## 2. App Screens & Navigation

The app has **4 main tabs** at the bottom, plus a **floating ➕ button** in the center to add expenses.

```mermaid
flowchart TD
    subgraph Main_Tabs["📱 Main Tab Bar"]
        T1["👥 Friends\nTab"]
        T2["👨‍👩‍👧‍👦 Groups\nTab"]
        T3["🕐 Activity\nTab"]
        T4["👤 Profile\nTab"]
    end

    Plus["➕ Add Expense\n(Floating Button)"] --> AddExp["Add Expense Sheet"]

    T1 --> FriendsList["Friends List"]
    FriendsList --> FriendDetail["Friend Detail"]
    FriendDetail --> SettleUp["Settle Up"]
    FriendDetail --> Remind["Send Reminder"]

    T2 --> GroupsList["Groups List"]
    GroupsList --> GroupDetail["Group Detail"]
    GroupDetail --> SettleUp2["Settle Up"]

    T3 --> ActivityFeed["Activity Feed\n(Timeline of all actions)"]

    T4 --> ProfilePage["Profile Settings"]
    ProfilePage --> EditProfile["Edit Profile & Photo"]
    ProfilePage --> Charts["Spending Insights Charts"]
    ProfilePage --> Help["Help & Support"]
    ProfilePage --> Privacy["Privacy Policy"]
```

---

## 3. Authentication (Login / Signup)

Before you can use the app, you need to create an account. ExpenseBuddy gives you **3 ways** to get in:

| Method | How It Works |
|--------|-------------|
| **Email + Password** | Type your email and password to sign up or login |
| **Google Sign-In** | One-tap login with your Google account |
| **Forgot Password** | Get a password reset email sent to your inbox |

```mermaid
flowchart TD
    Open["🚀 Open App"] --> Splash["Splash Screen\n(checks if logged in)"]
    Splash -->|Already logged in| Home["🏠 Main Tab View"]
    Splash -->|Not logged in| Login["Login Screen"]

    Login -->|Email + Password| FireAuth["Firebase Auth\n(verifies credentials)"]
    Login -->|Google Sign-In| Google["Google OAuth"] --> FireAuth
    Login -->|New user?| Signup["Sign Up Screen"]

    Signup -->|Fill name, email,\nmobile, password| FireAuth
    FireAuth -->|Success| CreateDoc["Save user profile\nin Firestore"]
    CreateDoc --> Home

    Login -->|Forgot password?| Forgot["Forgot Password Screen"]
    Forgot -->|Enter email| ResetEmail["Firebase sends\nreset email ✉️"]
```

### Sign Up Validations
The app checks everything before creating your account:
- ✅ Name must be at least 2 characters
- ✅ Email must be valid (e.g. `name@email.com`)
- ✅ Password must meet strength rules (min 6 characters)
- ✅ Passwords must match
- ✅ Must accept Terms & Conditions

---

## 4. Friends

Friends are the people you share expenses with. You can **add**, **search**, and **remove** friends.

```mermaid
flowchart TD
    FriendTab["👥 Friends Tab"] --> Search["🔍 Search by name or email"]
    FriendTab --> AddFriend["➕ Add Friend"]
    FriendTab --> FriendList["List of Friends\n(with balance shown)"]
    FriendList --> Detail["Friend Detail Page"]

    AddFriend -->|Enter email| Lookup["Lookup in Firestore"]
    Lookup -->|User found| Bidir["Add friend for BOTH users\n(bidirectional)"]
    Lookup -->|User not found| Placeholder["Save as placeholder friend"]

    Detail --> SettleUp["💰 Settle Up"]
    Detail --> Remind["🔔 Send Payment Reminder"]
    Detail --> SharedGroups["📂 View Shared Groups"]
    Detail --> SharedExpenses["📋 View Shared Expenses"]
    Detail --> Remove["❌ Remove Friend\n(only if balance = ₹0)"]
```

### Key Rules
- **Bidirectional:** When you add a friend who is on ExpenseBuddy, they automatically see you in their friends list too.
- **Cannot remove** a friend if you still owe them money (or they owe you).
- **Reminder:** You can nudge a friend who owes you money — they'll get a push notification.

---

## 5. Groups

Groups let you organize expenses by occasion. For example: "Goa Trip", "Apartment Rent", or "Office Lunch".

```mermaid
flowchart TD
    GroupTab["👨‍👩‍👧‍👦 Groups Tab"] --> CreateGroup["➕ Create Group"]
    GroupTab --> GroupList["List of Groups\n(with balance shown)"]
    GroupList --> GroupDetail["Group Detail Page"]

    CreateGroup --> PickType["Pick Group Type"]
    PickType --> TypeHome["🏠 Home"]
    PickType --> TypeTrip["✈️ Trip"]
    PickType --> TypeOffice["🏢 Office"]
    PickType --> TypeCouple["❤️ Couple"]
    PickType --> TypeOther["📁 Other"]

    CreateGroup --> AddMembers["Add Friends as Members"]
    CreateGroup --> PickIcon["Choose Group Icon"]

    GroupDetail --> ViewExpenses["See all Group Expenses"]
    GroupDetail --> AddExpense["➕ Add Expense to Group"]
    GroupDetail --> SettleUp["💰 Settle Up within Group"]
    GroupDetail --> SimplifiedDebts["🧮 View Simplified Debts"]
    GroupDetail --> DeleteGroup["🗑️ Delete Group\n(only if all balances = ₹0)"]
```

### Key Rules
- A group **cannot be deleted** unless everyone in the group is fully settled (no one owes anyone).
- Each group has its own **icon** and **type** (Home, Trip, Office, Couple, Other).
- The group balance shows how much YOU owe or are owed inside that specific group.

---

## 6. Adding an Expense (The Core Feature)

This is the heart of the app. When someone pays for something, you record it here.

```mermaid
flowchart TD
    Tap["Tap ➕ Button"] --> Form["Add Expense Form"]
    Form --> Title["Enter Title\n(e.g. 'Movie Tickets')"]
    Form --> Amount["Enter Amount\n(e.g. ₹500)"]
    Form --> Category["Pick Category"]
    Form --> Group["Select Group"]
    Form --> Payer["Who Paid?"]
    Form --> Participants["Who was involved?"]
    Form --> SplitType["How to Split?"]
    Form --> Note["Optional Note"]

    SplitType --> Equal["Equal Split\n₹500 ÷ 2 = ₹250 each"]
    SplitType --> Unequal["Unequal Split\nYou: ₹300, Bob: ₹200"]
    SplitType --> Percentage["Percentage Split\nYou: 60%, Bob: 40%"]
    SplitType --> Exact["Exact Amount\nType exact share for each"]

    Form -->|Save| Validate["Validate all fields"]
    Validate -->|✅ Pass| Convert["Convert to base currency (INR)"]
    Convert --> SaveDB["Save to Firebase"]
    SaveDB --> Notify["🔔 Notify all participants"]
```

### 10 Expense Categories

| Category | Icon | Category | Icon |
|----------|------|----------|------|
| 🍔 Food & Drink | fork.knife | 🚗 Transport | car |
| 🛍️ Shopping | bag | 🎮 Entertainment | gamecontroller |
| ⚡ Utilities | bolt | 🏠 Rent | house |
| ✈️ Travel | airplane | ❤️ Health | heart |
| 📚 Education | book | ⋯ Other | ellipsis |

### 4 Split Types Explained

```mermaid
flowchart LR
    subgraph Equal["Equal Split"]
        E1["₹600 Pizza"] --> E2["You: ₹200\nBob: ₹200\nCharlie: ₹200"]
    end

    subgraph Unequal["Unequal Split"]
        U1["₹600 Pizza"] --> U2["You: ₹300\nBob: ₹200\nCharlie: ₹100"]
    end

    subgraph Percent["Percentage Split"]
        P1["₹600 Pizza"] --> P2["You: 50% = ₹300\nBob: 30% = ₹180\nCharlie: 20% = ₹120"]
    end

    subgraph Exact["Exact Amount"]
        X1["₹600 Pizza"] --> X2["You: ₹250\nBob: ₹250\nCharlie: ₹100"]
    end
```

### Rounding Precision
The **Equal Split** uses smart rounding. If ₹100 is split among 3 people:
- Person 1: ₹33.33
- Person 2: ₹33.33
- Person 3: ₹33.34 ← absorbs the remainder

This ensures the total always adds up exactly.

---

## 7. Settle Up (Paying Back)

When someone owes money and pays it back, you record a **settlement**.

```mermaid
sequenceDiagram
    participant You
    participant App as ExpenseBuddy
    participant DB as Firebase

    You->>App: Open "Settle Up"
    App->>App: Show list of friends with balances
    You->>App: Select Bob (you owe ₹250)
    App->>App: Auto-fill amount = ₹250
    You->>App: Tap "Record Payment"
    App->>App: Convert to base currency (INR)
    App->>DB: Save settlement record
    DB-->>App: ✅ Saved
    App-->>You: 🎉 "Payment Recorded!"
```

### Smart Settlement Distribution
If Bob and you are in **multiple groups**, and you settle globally (not inside a specific group), ExpenseBuddy **automatically distributes** the payment across all your shared groups — paying off group-by-group until the full amount is covered.

```mermaid
flowchart TD
    Global["Global Settle Up: ₹500"] --> Check["Check shared groups"]
    Check --> G1["Goa Trip:\nYou owe Bob ₹200"]
    Check --> G2["Apartment:\nYou owe Bob ₹250"]
    Check --> G3["Office Lunch:\nYou owe Bob ₹100"]

    G1 -->|Pay ₹200| Settle1["Group Goa Trip: ₹200 settled"]
    G2 -->|Pay ₹250| Settle2["Group Apartment: ₹250 settled"]
    G3 -->|Remaining ₹50| Settle3["Group Office: ₹50 settled\n(₹50 still owed)"]
```

---

## 8. Debt Simplification (The Smart Math)

When money flows between many people, ExpenseBuddy **simplifies the debts** to the **minimum number of payments**.

```mermaid
flowchart LR
    subgraph Before["❌ Before Simplification\n(3 transactions)"]
        A1["You"] -->|₹100| B1["Bob"]
        B1 -->|₹100| C1["Charlie"]
        A1 -->|₹50| C1
    end

    subgraph After["✅ After Simplification\n(1 transaction)"]
        A2["You"] -->|₹150| C2["Charlie"]
        B2["Bob"] -.->|Balance ₹0| B2
    end
```

### How It Works (Greedy Algorithm)
1. Calculate the **net balance** for each person (positive = owed money, negative = owes money)
2. Match the **largest debtor** with the **largest creditor**
3. Transfer the minimum of what one owes and the other is owed
4. Repeat until all balances are zero

---

## 9. Activity Feed

The **Activity tab** shows a real-time timeline of everything that happens:

```mermaid
flowchart TD
    Activity["🕐 Activity Tab"] --> Today["📅 Today"]
    Activity --> Yesterday["📅 Yesterday"]
    Activity --> ThisWeek["📅 This Week"]
    Activity --> ThisMonth["📅 This Month"]
    Activity --> Earlier["📅 Earlier"]

    Today --> Types["Activity Types"]
    Types --> T1["📝 Expense Added\n'Bob paid ₹500 for Movie'"]
    Types --> T2["✅ Settlement\n'You paid Bob ₹250'"]
    Types --> T3["👨‍👩‍👧‍👦 Group Created\n'You created Goa Trip'"]
```

The feed rebuilds automatically (with debouncing) whenever expenses, settlements, or group data changes.

---

## 10. Notifications

ExpenseBuddy has a **3-layer notification system**:

```mermaid
flowchart TD
    Event["New Expense or Reminder Created"] --> Check{"Is app in\nforeground?"}

    Check -->|Yes| InApp["🔔 In-App Banner\n(slides down from top,\nauto-dismisses in 4 sec)"]
    Check -->|No| System["📲 System Push Notification\n(banner + sound on lock screen)"]

    System -->|User taps| DeepLink["Deep Link:\nOpen app → Navigate to\nthat specific expense"]

    CloudFn["☁️ Cloud Function\n(Firebase)"] -->|New expense created| Push["Send FCM Push\nto all participants"]
    CloudFn2["☁️ Cloud Function\n(Firebase)"] -->|New reminder created| Push2["Send FCM Push\nto the friend"]
```

### Notification Types
| Type | When It Triggers |
|------|-----------------|
| 💰 New Expense | Someone in your group adds an expense |
| ⏰ Reminder | A friend reminds you to pay up |

---

## 11. Profile & Settings

The Profile tab is your personal dashboard with settings and account management.

```mermaid
flowchart TD
    Profile["👤 Profile Tab"]
    Profile --> Card["Profile Card\n(Name, Email, Photo,\nMember since date)"]
    Profile --> Stats["Quick Stats\n(Friends count, Groups count,\nExpenses count)"]
    Profile --> Settings["⚙️ Settings"]
    Profile --> Logout["🚪 Log Out"]
    Profile --> Delete["🗑️ Delete Profile"]

    Settings --> DarkMode["🌙 Dark Mode Toggle"]
    Settings --> Notifications["🔔 Notifications Toggle"]
    Settings --> Currency["💱 Currency Picker\n(₹ INR, $ USD, € EUR, £ GBP, ¥ JPY)"]
    Settings --> Help["❓ Help & Support"]
    Settings --> Charts["📊 Spending Insights"]
    Settings --> Privacy["🔒 Privacy Policy"]

    Card -->|Tap| EditProfile["Edit Profile Page\n(change name, photo etc.)"]

    Charts --> BarChart["📊 Friend Balances\n(Bar Chart)"]
    Charts --> PieChart["🥧 Category Spending\n(Donut Chart)"]
    Charts --> Summary["📋 Quick Summary\n(total expenses, balance,\nactive friends)"]
```

### Profile Deletion Rules
You **cannot delete** your profile if you have any outstanding balances. You must settle up with everyone first. When deleted:
1. ❌ User document removed from Firestore
2. ❌ Friends subcollection removed
3. ❌ Reminders subcollection removed
4. ❌ Firebase Auth account deleted
5. ❌ Google Sign-In session cleared

If the auth deletion fails (e.g. you need to re-login), the app **rolls back** and restores your Firestore data.

---

## 12. Multi-Currency Support

ExpenseBuddy stores all amounts in **INR (₹)** as the base currency. When you switch your display currency, amounts are converted for display and input — but always stored in INR.

```mermaid
flowchart LR
    Input["User enters $10 USD"] --> Convert["Convert to INR\n($10 × rate = ₹830)"]
    Convert --> Store["Store ₹830\nin Firebase"]
    Store --> Display["Display as $10\nor ₹830 or €9.20\n(based on user's chosen currency)"]
```

---

## 13. How the Code is Organized (Architecture)

```mermaid
flowchart TD
    subgraph Views["📱 Views (26 screens)"]
        Auth["Auth:\nLogin, Signup, Forgot Password,\nSplash, Terms"]
        Friends["Friends:\nList, Detail, Add Friend"]
        Groups["Groups:\nList, Detail, Create Group"]
        Expenses["Expenses:\nAdd Expense, Detail, Settle Up"]
        ActivityV["Activity:\nActivity Feed"]
        ProfileV["Profile:\nProfile, Edit, Charts,\nHelp, Privacy"]
    end

    subgraph ViewModels["🧠 ViewModels"]
        AuthVM["AuthViewModel\n(login, signup, Google sign-in,\nforgot password)"]
        ExpenseVM["ExpenseViewModel\n(validation, split calculations,\nsave expense)"]
    end

    subgraph Services["⚙️ Services"]
        AuthSvc["AuthService\n(Firebase Auth, Google Sign-In,\ndelete profile)"]
        DataSvc["DataService\n(real-time Firestore listeners,\nCRUD for friends/groups/expenses/settlements,\nactivity feed, balance calculations)"]
        NotifSvc["NotificationService\n(local + push notifications,\nin-app banners, deep-linking,\nreminders)"]
        CacheSvc["UserCache\n(in-memory ID→User lookup,\nauto-fetches unknown users)"]
    end

    subgraph Models["📦 Models"]
        User["User"]
        Expense["Expense + ExpenseSplit"]
        Group["ExpenseGroup"]
        Settlement["Settlement"]
        ActivityM["ActivityItem"]
        NotifPayload["NotificationPayload"]
    end

    subgraph Utilities["🔧 Utilities"]
        Calc["ExpenseCalculator\n(split math, balance calculation,\ndebt simplification)"]
        Net["NetworkMonitor\n(checks internet connection)"]
        Router["NavigationRouter\n(manages navigation state\nfor all 4 tabs)"]
        Design["DesignSystem\n(colors, fonts, gradients,\nreusable components)"]
    end

    subgraph Backend["☁️ Firebase Backend"]
        FireAuth["Firebase Auth"]
        Firestore["Cloud Firestore"]
        FCM["Firebase Cloud Messaging"]
        CloudFns["Cloud Functions\n(push notification triggers)"]
    end

    Views --> ViewModels
    ViewModels --> Services
    Services --> Models
    Services --> Backend
    Utilities --> Services
```

---

## 14. Real-Time Data Sync

ExpenseBuddy uses **6 Firestore Snapshot Listeners** that keep your app data always up-to-date:

```mermaid
flowchart TD
    Firebase["☁️ Firebase Firestore"]

    Firebase -->|Listener 1| Groups["Groups\n(where you are a member)"]
    Firebase -->|Listener 2| Expenses["Expenses\n(where you are a participant)"]
    Firebase -->|Listener 3| Settlements["Settlements\n(where you are involved)"]
    Firebase -->|Listener 4| Friends["Your Friends List\n(private subcollection)"]
    Firebase -->|Listener 5| CurrentUser["Your Profile\n(real-time updates)"]
    Firebase -->|Listener 6| Reminders["Your Reminders\n(unread only)"]

    Groups --> Sync["All data syncs\ninstantly to your phone"]
    Expenses --> Sync
    Settlements --> Sync
    Friends --> Sync
    CurrentUser --> Sync
    Reminders --> Sync

    Sync --> Feed["Activity Feed\nrebuilds automatically"]
    Sync --> Cache["User Cache\nupdates names & photos"]
    Sync --> Notif["Notifications\ntrigger for new items"]
```

---

## 15. Firestore Database Structure

```mermaid
erDiagram
    USERS {
        string id PK
        string name
        string email
        string mobileNumber
        string profileImage
        string fcmToken
        bool hasAcceptedTerms
        date createdAt
    }

    USERS ||--o{ FRIENDS : "has subcollection"
    USERS ||--o{ REMINDERS : "has subcollection"

    FRIENDS {
        string id PK
        string name
        string email
        string profileImage
    }

    REMINDERS {
        string fromUserId
        string message
        double amount
        bool read
        date createdAt
    }

    GROUPS {
        string id PK
        string name
        string_array memberIds
        string createdByUserId
        string groupIcon
        string groupType
        date createdAt
    }

    EXPENSES {
        string id PK
        string title
        double amount
        string paidByUserId
        string_array participantIds
        string splitType
        json splits
        string groupId FK
        string category
        string note
        string createdByUserId
        date createdAt
    }

    SETTLEMENTS {
        string id PK
        string fromUserId
        string toUserId
        double amount
        string_array participantIds
        string groupId FK
        string note
        date date
    }

    GROUPS ||--o{ EXPENSES : "contains"
    GROUPS ||--o{ SETTLEMENTS : "contains"
    USERS ||--o{ EXPENSES : "participates in"
    USERS ||--o{ SETTLEMENTS : "involved in"
```

---

## 16. Cloud Functions (Server-Side)

Two Firebase Cloud Functions run automatically when data is created:

```mermaid
sequenceDiagram
    participant User as You
    participant App as ExpenseBuddy
    participant FS as Firestore
    participant CF as Cloud Function
    participant FCM as Firebase Cloud Messaging
    participant Friend as Friend's Phone

    Note over User, Friend: Flow 1: New Expense Notification
    User->>App: Add new expense
    App->>FS: Save expense document
    FS->>CF: Trigger: "expenses/{id}" created
    CF->>FS: Lookup FCM tokens of participants
    CF->>FCM: Send push notification
    FCM->>Friend: 📲 "💰 Bob added 'Movie' for ₹500"

    Note over User, Friend: Flow 2: Payment Reminder
    User->>App: Tap "Remind" on friend
    App->>FS: Save reminder document
    FS->>CF: Trigger: "reminders/{id}" created
    CF->>FS: Lookup friend's FCM token
    CF->>FCM: Send push notification
    FCM->>Friend: 📲 "⏰ Bob is reminding you..."
```

---

## 17. Design System

The app uses a custom design system with:

- **Dark/Light Mode** — toggleable from Profile settings
- **Custom Color Palette** — primary gradients, card backgrounds, green (owed), red (owe), settled gray
- **Rounded Typography** — using the `.rounded` system font design
- **Glassmorphism Effects** — used in charts and cards
- **Haptic Feedback** — light taps on tab switches, heavy impact on "Add Expense"
- **Custom Dock Tab Bar** — a floating capsule-shaped tab bar that hides on sub-pages
- **Smooth Animations** — spring animations on transitions, tab switching, and banner slides

---

## 18. Key Feature Summary

| Feature | Description |
|---------|-------------|
| 🔐 **Email/Password Auth** | Sign up and login with email and password |
| 🔑 **Google Sign-In** | One-tap Google OAuth login |
| 🔄 **Forgot Password** | Email-based password reset |
| 👥 **Friends** | Add, search, remove friends (bidirectional) |
| 🔔 **Reminders** | Nudge friends who owe you money |
| 👨‍👩‍👧‍👦 **Groups** | Organize expenses by occasion (5 types) |
| 💰 **Add Expense** | Record who paid and split 4 ways |
| 📂 **10 Categories** | Food, Transport, Shopping, Entertainment, etc. |
| 🤝 **Settle Up** | Record payments with auto-distribution |
| 🧮 **Debt Simplification** | Minimize number of transactions |
| 📊 **Charts** | Bar chart (balances) + Donut chart (categories) |
| 🌙 **Dark Mode** | System-wide dark/light theme toggle |
| 💱 **Multi-Currency** | Display in INR, USD, EUR, GBP, or JPY |
| 📲 **Push Notifications** | Real-time alerts via FCM + Cloud Functions |
| 🔔 **In-App Banners** | Floating notification banners when app is open |
| 🗑️ **Delete Profile** | Full account deletion with safety checks |
| ⚡ **Real-Time Sync** | 6 Firestore listeners keep everything up-to-date |
| 🌐 **Offline Aware** | Network Monitor tracks connectivity |
| 📱 **Premium UI** | Custom tab bar, haptics, glassmorphism, animations |

---

*ExpenseBuddy — take the awkwardness and math out of sharing money. You enter the numbers, the app handles the rest.* ❤️
