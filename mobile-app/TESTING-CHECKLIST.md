# 📱 Flutter App Testing Checklist

## 🚀 **Quick Start Testing Guide**

### **Prerequisites:**
1. ✅ Backend server running (`npm start` in backend-api)
2. ✅ Flutter app running (`flutter run` in mobile-app)
3. ✅ Redis running (or in-memory fallback active)

---

## **🎯 Phase 1: Single User Tests (Start Here)**

### **✅ Test 1.1: Basic Seat Selection**
**Time: 2 minutes**

1. **Open** seat selection screen
2. **Tap** any available seat (should be gray/white)
3. **Verify**:
   - ✅ Seat turns **🟧 orange** with ✓ icon
   - ✅ Timer appears: "Selection expires in 4:59..."  
   - ✅ Selection counter shows "1"
   - ✅ "Continue" button becomes active

**✅ Expected**: Orange seat, countdown timer, no errors

---

### **✅ Test 1.2: Multiple Seat Selection** 
**Time: 1 minute**

1. **Select** 2-3 more seats
2. **Verify**:
   - ✅ All selected seats are **🟧 orange**
   - ✅ Timer continues (doesn't reset)
   - ✅ Counter shows correct number

**✅ Expected**: Multiple orange seats, single timer

---

### **✅ Test 1.3: Seat Deselection**
**Time: 1 minute**

1. **Tap** a selected seat to deselect
2. **Deselect all** seats
3. **Verify**:
   - ✅ Deselected seats return to gray/white
   - ✅ Timer stops when all seats deselected
   - ✅ Counter updates correctly

**✅ Expected**: Seats turn gray, timer disappears

---

### **✅ Test 1.4: Timer Behavior** 
**Time: 30 seconds**

1. **Select** a seat, watch timer
2. **Verify**:
   - ✅ Timer counts down: 4:59, 4:58, 4:57...
   - ✅ Timer is in **orange box** with clock icon
   - ✅ Format is MM:SS

**✅ Expected**: Smooth countdown, correct format

---

## **🎨 Phase 2: Color State Testing (Visual Verification)**

### **✅ Test 2.1: Seat Color Legend**
**Time: 1 minute**

1. **Check bottom legend** shows:
   - ⚪ Available
   - 🟧 Selected  
   - 🟡 Locked
   - 🟣 VIP
   - 🔴 Booked

2. **Compare** legend colors with actual seat colors

**✅ Expected**: Legend matches seat colors exactly

---

### **✅ Test 2.2: Different Seat Types**
**Time: 2 minutes**

Look for seats in different states:
- ✅ **Gray/White** = Available seats (can tap)
- ✅ **🟧 Orange** = Your selected seats (can tap to deselect)
- ✅ **🟣 Purple** = VIP/Premium seats (higher price)
- ✅ **🔴 Red with ✖** = Permanently booked seats (cannot tap)

**✅ Expected**: Different colors for different states

---

## **👥 Phase 3: Multi-User Testing (Need 2 devices)**

### **✅ Test 3.1: Two Users, Different Seats**
**Time: 3 minutes**

**Device A**:
1. Select seats A1, A2

**Device B**: 
1. Select seats B1, B2
2. Check what Device B sees:
   - ✅ B1, B2 = **🟧 Orange** (own selection)
   - ✅ A1, A2 = **🟡 Yellow/Locked** (other user)

**Device A**:
1. Check what Device A sees:
   - ✅ A1, A2 = **🟧 Orange** (own selection)  
   - ✅ B1, B2 = **🟡 Yellow/Locked** (other user)

**✅ Expected**: Each user sees others' seats as yellow/locked

---

### **✅ Test 3.2: Seat Competition**
**Time: 2 minutes**

**Device A**: Select seat C1 first

**Device B**: Try to select same seat C1
- ✅ **Should fail** - seat appears yellow/locked
- ✅ **May show** error message about seat being locked

**✅ Expected**: Second user cannot select already-locked seat

---

### **✅ Test 3.3: Real-time Updates** 
**Time: 3 minutes**

**Device A**: Select seat D1

**Device B**: Wait up to 15 seconds
- ✅ Seat D1 should become **🟡 yellow/locked** 

**Device A**: Deselect seat D1

**Device B**: Wait up to 15 seconds  
- ✅ Seat D1 should become **⚪ available** again

**✅ Expected**: Changes appear within 15 seconds (polling interval)

---

## **⏱️ Phase 4: Timer Testing**

### **✅ Test 4.1: Session Expiration**
**Time: 5+ minutes (or speed up in code)**

1. **Select** seats
2. **Wait** for timer to reach 0:00 
3. **Verify** what happens:
   - ✅ All seats automatically deselected
   - ✅ Orange message: "Selection time expired..."
   - ✅ Timer disappears
   - ✅ Seats become available for others

**✅ Expected**: Clean expiration, no permanent locks

---

## **🚨 Phase 5: Error Testing**

### **✅ Test 5.1: Network Issues**
**Time: 2 minutes**

1. **Select** seats normally
2. **Turn off WiFi** for 30 seconds
3. **Turn WiFi back on**
4. **Verify**: App recovers gracefully, seats still selected

**✅ Expected**: No crashes, state recovery

---

### **✅ Test 5.2: App Backgrounding**
**Time: 1 minute**

1. **Select** seats
2. **Background app** (home button)
3. **Return to app** after 30 seconds
4. **Verify**: Timer continues, seats still selected

**✅ Expected**: Timer continues running

---

## **📊 Success Criteria**

### **✅ Must Pass All:**
- ✅ **Seat colors** match the legend exactly
- ✅ **Timer** counts down smoothly from 5:00
- ✅ **Multi-user** shows yellow locks for other users
- ✅ **Expiration** cleans up seats automatically
- ✅ **No crashes** during any test
- ✅ **Real-time updates** within 15 seconds
- ✅ **Network recovery** works after disconnection

---

## **🔧 Troubleshooting**

### **❌ Timer not showing:**
- Check if seat selection actually worked
- Verify backend is running
- Check console for errors

### **❌ Colors wrong:**
- Restart app to reload latest code changes
- Check if seat data is loading correctly

### **❌ Multi-user not working:**
- Verify both users have different accounts
- Check network connectivity
- Ensure polling is working (15-second updates)

### **❌ Backend errors:**
- Check `npm start` is running in backend-api
- Verify Redis connection (or in-memory fallback)
- Check server logs for errors

---

## **📱 Testing Commands**

```bash
# Start backend
cd backend-api
npm start

# Start Flutter app  
cd mobile-app
flutter run

# Monitor Redis (optional)
cd backend-api
node monitor-redis.js

# API testing (optional)
node test-seat-locking.js
```

---

**🎉 Ready to Test!**

**Start with Phase 1** - it's the foundation for everything else. Each test should take 1-3 minutes and show immediate results.

**Problem?** Check the troubleshooting section or ask for help! 🤝