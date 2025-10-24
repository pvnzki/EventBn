# Guest Mode - User Flow Guide

## 🎯 Guest Mode User Journey

### Step 1: Login Screen
```
┌─────────────────────────────────┐
│         EventBn Logo            │
│                                 │
│      Welcome Back!              │
│   Sign in to your account       │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Email                     │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Password           👁️     │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │        Login              │  │ ← User clicks here
│  └───────────────────────────┘  │
│                                 │
│  Don't have an account? Sign up │
│                                 │
│        ──────  OR  ──────        │
│                                 │
│  ┌───────────────────────────┐  │
│  │ 👤  Browse as Guest       │  │ ← NEW! Guest clicks here
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

---

### Step 2: Guest Home Screen (No Bottom Navigation)
```
┌─────────────────────────────────┐
│  EventBn     [Login Button]  →  │ ← Login button for guests
├─────────────────────────────────┤
│                                 │
│  🔍 Search for events...        │
│                                 │
│  ┌─ Categories ───────────────┐ │
│  │ All | Concerts | Sports... │ │
│  └────────────────────────────┘ │
│                                 │
│  ┌─ Banner Carousel ──────────┐ │
│  │  🎵 Featured Event        │ │
│  │  [Auto-scrolling]         │ │
│  └───────────────────────────┘ │
│                                 │
│  📅 Upcoming Events             │
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │ Event 1  │  │ Event 2  │    │ ← Tappable
│  │ Concert  │  │ Sports   │    │
│  └──────────┘  └──────────┘    │
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │ Event 3  │  │ Event 4  │    │
│  └──────────┘  └──────────┘    │
│                                 │
└─────────────────────────────────┘
    ↑ NO BOTTOM NAV BAR HERE
```

---

### Step 3: Guest Event Details Screen
```
┌─────────────────────────────────┐
│  ← Back                         │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │                             ││
│  │    Event Cover Image        ││
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  🎵 Music Festival 2025         │
│                                 │
│  📅 Date: Dec 15, 2025          │
│  📍 Location: Stadium           │
│  💰 Price: From LKR 2000        │
│                                 │
│  ─────── Description ────────   │
│  Join us for the biggest music  │
│  festival of the year featuring │
│  top artists...                 │
│                                 │
│  ─────── Organizer ──────────   │
│  🏢 Event Company Ltd           │
│                                 │
│  ┌───────────────────────────┐  │
│  │    📅 Book Event          │  │ ← Guest clicks here
│  └───────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
```

---

### Step 4: Login Required Dialog
```
┌─────────────────────────────────┐
│                                 │
│    ┌─────────────────────────┐  │
│    │  Login Required         │  │
│    │                         │  │
│    │  Please login or create │  │
│    │  an account to book     │  │
│    │  tickets.               │  │
│    │                         │  │
│    │  [Cancel]  [Login] →    │  │ ← Redirects to login
│    └─────────────────────────┘  │
│                                 │
│                                 │
└─────────────────────────────────┘
```

---

## 🔄 State Transitions

### Guest Mode States

```
┌────────────────┐
│  Not in App    │
└────────┬───────┘
         │
         ↓
┌────────────────┐     Browse as Guest     ┌─────────────────┐
│  Login Screen  │ ───────────────────────→ │  Guest Home     │
└────────┬───────┘                          │  (No Bottom Nav)│
         │                                  └────────┬────────┘
         │ Login                                     │
         │                                           │ View Event
         ↓                                           ↓
┌────────────────┐                          ┌─────────────────┐
│  Authenticated │                          │ Guest Event     │
│  Home Screen   │                          │ Details         │
│  (With Nav)    │                          └────────┬────────┘
└────────────────┘                                   │
                                                     │ Try to Book
                                                     ↓
                                            ┌─────────────────┐
                                            │ Login Required  │
                                            │ Dialog          │
                                            └────────┬────────┘
                                                     │
                                                     ↓
                                            Back to Login Screen
```

---

## 🎨 UI Components

### Header Component States

**Authenticated User:**
```
┌──────────────────────────────┐
│ EventBn Logo        🔔       │
│                     Notif    │
└──────────────────────────────┘
```

**Guest User:**
```
┌──────────────────────────────┐
│ EventBn Logo    [Login]      │
│                   Button     │
└──────────────────────────────┘
```

---

## 📱 Navigation Comparison

### Guest Mode Navigation
```
Routes without bottom nav:
├── /guest-home
└── /guest/events/:eventId

User can only:
- Browse events
- View details
- Click login button
```

### Authenticated Mode Navigation
```
Routes with bottom nav:
├── /home
├── /events/:eventId
├── /tickets
├── /profile
└── /explore

User can:
- Everything guests can do
- Book tickets
- View ticket history
- Manage profile
- Explore posts
```

---

## 🎯 Call-to-Action Points

Guest Mode has **3 conversion points** to encourage login:

1. **Header Login Button**
   - Always visible
   - Prominent placement
   - Quick access

2. **Book Event Button**
   - Primary action
   - Shows dialog with reason
   - Clear next step

3. **Login Required Dialog**
   - Contextual explanation
   - Two clear options
   - Smooth transition

---

## 💡 User Experience Highlights

### ✨ Benefits of Guest Mode:
- **Low friction** - No signup required to browse
- **Full catalog access** - See all events
- **Informed decision** - Review before committing
- **Easy conversion** - One-click login when ready

### 🎯 Design Principles:
- **Minimal interruption** - Browse freely
- **Clear communication** - Explain login benefits
- **Consistent design** - Same look and feel
- **Smooth transitions** - No jarring redirects

---

## 🔍 Testing Scenarios

### Happy Path:
1. Open app → Login screen
2. Click "Browse as Guest" → Guest home
3. Browse events → View details
4. Click "Book Event" → Login dialog
5. Click "Login" → Login screen
6. Login successfully → Authenticated home
7. Book tickets → Success ✅

### Edge Cases:
- Guest hits back button → Stays in guest home
- Guest refreshes → Maintains guest state
- Guest tries notification → No notification icon shown
- Logged user opens app → Skips guest mode
- Guest logs out → Returns to login (not guest mode)

---

## 📊 Success Metrics

Track these metrics to measure guest mode success:

**Engagement:**
- % of users choosing guest mode
- Average events viewed per guest session
- Time spent in guest mode

**Conversion:**
- Guest → Registered user rate
- Events viewed before conversion
- Booking dialog interaction rate

**User Flow:**
- Drop-off points in guest journey
- Most common conversion trigger
- Return visitor rate (guest → registered)

---

## 🚀 Launch Checklist

Before releasing guest mode:

- [ ] Test "Browse as Guest" button
- [ ] Verify guest home loads correctly
- [ ] Check event details in guest mode
- [ ] Confirm login dialog appears on book attempt
- [ ] Test login from guest mode
- [ ] Verify guest mode exits after login
- [ ] Check header shows correct buttons
- [ ] Ensure no bottom nav in guest routes
- [ ] Test back button behavior
- [ ] Verify state persistence

---

*Visual Guide Version: 1.0*  
*Last Updated: January 2025*
