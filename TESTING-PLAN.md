# 🧪 EventBn Seat Locking System - Testing Plan

## 🎯 **Testing Overview**

This comprehensive testing plan covers all aspects of the Redis-based seat locking system, from basic functionality to high-load scenarios and edge cases.

---

## 📋 **Phase 1: Single User Basic Testing**

### **✅ Test 1.1: Basic Seat Selection**
**Objective**: Verify basic seat selection and color changes work correctly.

**Steps**:
1. Open the mobile app and navigate to seat selection
2. Select a single seat (e.g., A1)
3. Verify UI changes:
   - ✅ Seat turns **orange** with checkmark icon
   - ✅ Global timer starts showing "4:59, 4:58..."
   - ✅ Selection counter shows "1"
   - ✅ Continue button becomes active

**Expected Results**:
- Seat color: 🟧 Orange with ✓ icon
- Timer: Shows countdown from 5:00
- No network errors in console

### **✅ Test 1.2: Multiple Seat Selection**
**Objective**: Test selecting multiple seats and verify timer behavior.

**Steps**:
1. Select 3-4 different seats
2. Verify each seat turns orange
3. Check timer behavior (should not reset for additional seats)
4. Try to select more than allowed (if limit exists)

**Expected Results**:
- All selected seats: 🟧 Orange
- Timer: Continues from when first seat was selected
- UI updates correctly

### **✅ Test 1.3: Seat Deselection**
**Objective**: Test removing seats from selection.

**Steps**:
1. Select 3 seats
2. Deselect 1 seat by tapping it again
3. Deselect all seats
4. Verify timer behavior

**Expected Results**:
- Deselected seats return to available state
- Timer stops when all seats deselected
- Selection counter updates correctly

### **✅ Test 1.4: Timer Expiration**
**Objective**: Test session timeout behavior.

**Steps**:
1. Select 2 seats
2. Wait for timer to reach 0:00 (or speed up for testing)
3. Verify expiration behavior

**Expected Results**:
- Seats automatically deselected
- Orange message: "Selection time expired. Please select your seats again."
- Timer disappears
- Seats become available again

---

## 🤝 **Phase 2: Multi-User Concurrency Testing**

### **✅ Test 2.1: Two Users, Different Seats**
**Objective**: Verify normal multi-user operation.

**Setup**: Use 2 devices/browsers with different user accounts.

**Steps**:
1. **User A**: Select seats A1, A2
2. **User B**: Select seats B1, B2
3. Verify both users see correct seat states

**Expected Results**:
- **User A sees**: A1, A2 (🟧 orange), B1, B2 (🟡 yellow/locked)
- **User B sees**: B1, B2 (🟧 orange), A1, A2 (🟡 yellow/locked)
- Both timers run independently

### **✅ Test 2.2: Seat Competition (Same Seat)**
**Objective**: Test what happens when users try to select the same seat.

**Steps**:
1. **User A**: Select seat A1
2. **User B**: Try to select seat A1 (should be locked)
3. Verify error handling

**Expected Results**:
- **User B**: Cannot select A1, sees 🟡 yellow/locked
- **User B**: Gets error message when attempting to select
- No crashes or inconsistent states

### **✅ Test 2.3: Lock Release and Competition**
**Objective**: Test what happens when locks expire and become available.

**Steps**:
1. **User A**: Select seat A1, wait for timer to expire
2. **User B**: Try to select A1 after A's lock expires
3. Verify seat becomes available

**Expected Results**:
- A1 becomes available (white/gray) after User A's lock expires
- User B can successfully select A1
- Real-time updates work correctly

### **✅ Test 2.4: Real-time Polling**
**Objective**: Verify that users see each other's actions in real-time.

**Steps**:
1. **User A**: Select a seat
2. **User B**: Should see the seat become locked within 15 seconds
3. **User A**: Release the seat
4. **User B**: Should see the seat become available

**Expected Results**:
- Polling interval: ~15 seconds maximum delay
- Consistent state across all users
- No phantom locks or availability

---

## ⏱️ **Phase 3: Timer Synchronization Testing**

### **✅ Test 3.1: Frontend vs Backend Timer Sync**
**Objective**: Verify 5-minute timers are synchronized.

**Setup**: Use browser dev tools to monitor network requests.

**Steps**:
1. Select a seat
2. Monitor the countdown timer
3. Check Redis TTL using Redis CLI: `TTL seat_lock:event:seat`
4. Verify both expire at roughly the same time

**Expected Results**:
- Frontend timer: 5:00 → 0:00
- Redis TTL: 300 seconds → 0
- Difference < 10 seconds

### **✅ Test 3.2: Payment Extension**
**Objective**: Test timer extension during payment flow.

**Steps**:
1. Select seats and start checkout
2. Verify timer extends to 10 minutes
3. Monitor Redis TTL changes

**Expected Results**:
- Timer extends to 10:00 during payment
- Redis TTL updates accordingly
- No interruptions during payment

---

## 🎨 **Phase 4: Seat Color State Testing**

### **✅ Test 4.1: All Color States**
**Objective**: Verify all seat colors display correctly.

**Test Data Setup**:
- Create seats with different states in database:
  - Available seats
  - VIP/Premium seats  
  - Permanently booked seats (`available: false`)

**Steps**:
1. Load seat map
2. Select some available seats
3. Have another user select different seats
4. Verify color legend matches actual colors

**Expected Results**:
| State | Color | Icon | Legend |
|-------|-------|------|---------|
| Available | Gray/White | None | ✅ Available |
| Selected | 🟧 Orange | ✓ | ✅ Selected |
| Locked | 🟡 Yellow | ⏰ | ✅ Locked |
| Booked | 🔴 Red | ✖ | ✅ Booked |
| VIP | 🟣 Purple | None | ✅ VIP |

### **✅ Test 4.2: Color Transitions**
**Objective**: Test smooth color transitions during state changes.

**Steps**:
1. Watch seat transition: Available → Selected → Locked → Available
2. Verify smooth animations
3. Check for any flickering or incorrect intermediate states

---

## 🚀 **Phase 5: Queue System Load Testing**

### **✅ Test 5.1: Queue Activation Threshold**
**Objective**: Test hybrid system switches to queue mode under load.

**Setup**: 
- Current threshold: 10 requests/minute
- Use testing script or multiple clients

**Steps**:
1. Send < 10 requests/minute → Should use direct processing
2. Send > 10 requests/minute → Should switch to queue
3. Monitor queue stats endpoint: `/api/seat-locks/events/{eventId}/hybrid/stats`

**Expected Results**:
- Low load: `"useQueue": false`, `"status": "normal-load"`
- High load: `"useQueue": true`, `"status": "high-load"`

### **✅ Test 5.2: Queue Processing Order**
**Objective**: Verify FIFO (first-in-first-out) queue processing.

**Steps**:
1. Simulate high load to trigger queue mode
2. Submit multiple seat lock requests rapidly
3. Monitor processing order via logs
4. Verify requests processed in submission order

**Expected Results**:
- Requests processed in exact FIFO order
- No queue jumping or lost requests
- Fair processing times

### **✅ Test 5.3: Queue Response Polling**
**Objective**: Test client polling for queued request results.

**Steps**:
1. Submit request that gets queued (status 202)
2. Use polling endpoint to check result
3. Verify timeout handling

**Expected Results**:
- Queued request returns: `"queued": true`, `requestId`
- Polling returns result when processed
- Timeout after 30 seconds if not processed

---

## 💥 **Phase 6: Edge Cases & Failure Testing**

### **✅ Test 6.1: Network Interruption**
**Objective**: Test behavior during network failures.

**Steps**:
1. Select seats normally
2. Disconnect network for 30 seconds
3. Reconnect and verify state
4. Test during queue polling

**Expected Results**:
- Graceful error handling
- State recovery after reconnection
- No lost selections or phantom locks

### **✅ Test 6.2: Redis Disconnection**
**Objective**: Test fallback to in-memory storage.

**Steps**:
1. Stop Redis server
2. Try to select seats
3. Verify fallback behavior
4. Restart Redis and test again

**Expected Results**:
- Seamless fallback to in-memory storage
- Warning logs about Redis connection
- Functionality continues working
- Switches back to Redis when available

### **✅ Test 6.3: App Crash Recovery**
**Objective**: Test lock release when app crashes.

**Steps**:
1. Select seats
2. Force close app (kill process)
3. Wait 5+ minutes
4. Reopen app and check seat availability

**Expected Results**:
- Redis TTL automatically releases locks
- Seats become available for other users
- No permanent phantom locks

### **✅ Test 6.4: Payment Flow Integration**
**Objective**: Test complete purchase flow.

**Steps**:
1. Select seats → Payment → Complete purchase
2. Verify seat becomes permanently booked
3. Check database state
4. Verify other users see seat as red/booked

**Expected Results**:
- Successful payment: seat becomes `available: false` in DB
- Seat color: 🔴 Red with ✖ icon
- Cannot be selected by anyone

---

## 🛠️ **Testing Tools & Setup**

### **Required Tools**:
1. **Mobile App**: Flutter app on device/simulator
2. **API Testing**: Postman or curl for backend testing
3. **Redis CLI**: For monitoring Redis state
4. **Database Client**: For checking seat availability states
5. **Load Testing**: Artillery or custom script for queue testing

### **Test Environment Setup**:
```bash
# 1. Start backend server
cd backend-api
npm start

# 2. Check Redis connection
redis-cli ping

# 3. Monitor Redis locks
redis-cli --scan --pattern "seat_lock:*"

# 4. Monitor queue length
curl http://localhost:3000/api/seat-locks/events/test-event/hybrid/stats
```

### **Test Data Requirements**:
- **Event ID**: `test-concert-123`
- **User Accounts**: At least 2 test users
- **Seat Map**: Mix of available, VIP, and pre-booked seats
- **Network**: Stable connection for multi-user tests

---

## 📊 **Success Criteria**

### **✅ All tests pass with these results**:
- ✅ **Zero data loss**: No phantom locks or lost selections
- ✅ **Consistent state**: All users see same seat states
- ✅ **Timer accuracy**: ±10 seconds between frontend/backend
- ✅ **Color accuracy**: All seat colors match their states
- ✅ **Queue fairness**: FIFO processing under high load
- ✅ **Graceful failures**: No crashes during edge cases
- ✅ **Performance**: <2 second response times in normal load

---

## 🚀 **Getting Started**

**Phase 1** is ready to test immediately with the current implementation!

1. **Start Backend**: `npm start` in backend-api directory
2. **Start Flutter App**: `flutter run` in mobile-app directory  
3. **Begin Test 1.1**: Basic seat selection testing

Would you like me to create automated test scripts for any of these scenarios? 🤖