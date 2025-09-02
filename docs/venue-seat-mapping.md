# Venue Seat Mapping Guide

This guide explains how to transform flat seat data into realistic venue-shaped seat maps.

## Enhanced Seat JSON Structure

### Option 1: Row/Column Based (Recommended)
```json
{
  "hasCustomSeating": true,
  "layout": "theater",
  "layoutConfig": {
    "aisleSpacing": 4,
    "stagePosition": "front"
  },
  "seats": [
    {
      "id": 1,
      "label": "A1",
      "price": 50,
      "available": true,
      "ticketType": "Premium",
      "row": "A",
      "column": 1,
      "section": "front"
    },
    {
      "id": 2,
      "label": "A2",
      "price": 50,
      "available": true,
      "ticketType": "Premium",
      "row": "A",
      "column": 2,
      "section": "front"
    }
  ]
}
```

### Option 2: Explicit Positioning
```json
{
  "hasCustomSeating": true,
  "layout": "concert",
  "layoutConfig": {
    "venueWidth": 800,
    "venueHeight": 600,
    "seatSize": 32
  },
  "seats": [
    {
      "id": 1,
      "label": "A1",
      "price": 50,
      "available": true,
      "ticketType": "Premium",
      "x": 100,
      "y": 200,
      "section": "left"
    }
  ]
}
```

## Supported Venue Layouts

### 1. Theater Layout
- **Description**: Traditional theater with rows facing a stage
- **Features**: 
  - Alphabetical rows (A, B, C...)
  - Numbered seats within rows
  - Aisles every 4-6 seats
  - Stage at the front

```json
{
  "layout": "theater",
  "layoutConfig": {
    "aisleSpacing": 4,
    "stagePosition": "front",
    "rowCurve": "slight"
  }
}
```

### 2. Concert Layout
- **Description**: Concert venue with left/center/right sections
- **Features**:
  - Multiple sections around stage
  - Standing areas supported
  - Wide stage area

```json
{
  "layout": "concert",
  "layoutConfig": {
    "sections": ["left", "center", "right"],
    "stageWidth": "full",
    "standingAreas": ["pit"]
  }
}
```

### 3. Conference Layout
- **Description**: Conference room with presentation screen
- **Features**:
  - Presentation screen at front
  - Table-style seating
  - Open floor plan

```json
{
  "layout": "conference",
  "layoutConfig": {
    "screenPosition": "front",
    "tableArrangement": "classroom"
  }
}
```

## Database Schema Enhancement

### Events Table
Add a `venue_layout` column:
```sql
ALTER TABLE events ADD COLUMN venue_layout VARCHAR(50) DEFAULT 'theater';
ALTER TABLE events ADD COLUMN layout_config JSON;
```

### Seats Table
Add positioning columns:
```sql
ALTER TABLE seats ADD COLUMN row_letter VARCHAR(5);
ALTER TABLE seats ADD COLUMN column_number INT;
ALTER TABLE seats ADD COLUMN section_name VARCHAR(20);
ALTER TABLE seats ADD COLUMN x_position INT;
ALTER TABLE seats ADD COLUMN y_position INT;
```

## API Response Structure

### Enhanced Seat Map Response
```json
{
  "success": true,
  "data": {
    "hasCustomSeating": true,
    "layout": "theater",
    "layoutConfig": {
      "aisleSpacing": 4,
      "stagePosition": "front",
      "venueCapacity": 500
    },
    "seats": [
      {
        "id": 1,
        "label": "A1",
        "price": 50,
        "available": true,
        "ticketType": "Premium",
        "row": "A",
        "column": 1,
        "section": "front"
      }
    ]
  }
}
```

## Implementation Steps

### 1. Update Your Database
```sql
-- Add layout columns to events table
ALTER TABLE events ADD COLUMN venue_layout VARCHAR(50) DEFAULT 'theater';
ALTER TABLE events ADD COLUMN layout_config JSON;

-- Add positioning columns to seats table
ALTER TABLE seats ADD COLUMN row_letter VARCHAR(5);
ALTER TABLE seats ADD COLUMN column_number INT;
ALTER TABLE seats ADD COLUMN section_name VARCHAR(20);

-- Update existing data
UPDATE seats SET 
  row_letter = SUBSTRING(label, 1, 1),
  column_number = CAST(SUBSTRING(label, 2) AS UNSIGNED),
  section_name = CASE 
    WHEN SUBSTRING(label, 1, 1) <= 'D' THEN 'front'
    WHEN SUBSTRING(label, 1, 1) <= 'H' THEN 'middle'
    ELSE 'back'
  END
WHERE label REGEXP '^[A-Z]+[0-9]+$';
```

### 2. Update Your API
```javascript
// In your seat map API endpoint
app.get('/api/events/:eventId/seatmap', async (req, res) => {
  try {
    const event = await Event.findById(req.params.eventId);
    const seats = await Seat.find({ eventId: req.params.eventId });
    
    res.json({
      success: true,
      data: {
        hasCustomSeating: event.hasCustomSeating,
        layout: event.venue_layout || 'theater',
        layoutConfig: event.layout_config || { aisleSpacing: 4 },
        seats: seats.map(seat => ({
          id: seat.id,
          label: seat.label,
          price: seat.price,
          available: seat.available,
          ticketType: seat.ticketType,
          row: seat.row_letter,
          column: seat.column_number,
          section: seat.section_name
        }))
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

### 3. Generate Seat Data
```javascript
// Helper function to generate venue-specific seat layout
function generateTheaterSeats(rows, seatsPerRow, pricing) {
  const seats = [];
  const rowLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  
  for (let rowIndex = 0; rowIndex < rows; rowIndex++) {
    const rowLetter = rowLetters[rowIndex];
    
    for (let seatNum = 1; seatNum <= seatsPerRow; seatNum++) {
      seats.push({
        label: `${rowLetter}${seatNum}`,
        row: rowLetter,
        column: seatNum,
        section: rowIndex < 4 ? 'front' : rowIndex < 8 ? 'middle' : 'back',
        price: pricing[rowIndex < 4 ? 'premium' : rowIndex < 8 ? 'standard' : 'economy'],
        available: true,
        ticketType: rowIndex < 4 ? 'Premium' : 'Economy'
      });
    }
  }
  
  return seats;
}
```

## Testing Your Venue Layout

1. **Test with sample data**: Create test events with different layouts
2. **Verify positioning**: Check that seats appear in correct positions
3. **Test interactions**: Ensure seat selection works across all layouts
4. **Mobile responsiveness**: Test on different screen sizes

## Advanced Features

### Custom Venue Shapes
- Implement custom venue shapes using SVG paths
- Support for irregular seating arrangements
- VIP sections and special areas

### Dynamic Pricing
- Price based on distance from stage
- Section-based pricing tiers
- Dynamic pricing based on demand

### Accessibility
- Wheelchair accessible seats
- Companion seats
- Clear sight lines indicators
