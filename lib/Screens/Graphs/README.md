# Animated Sales & Purchase Analytics

## Overview
This new screen provides beautiful animated graphs for sales and purchase data visualization with smooth animations and modern UI design.

## Features

### 🎨 **Visual Design**
- **Blue and Green Color Scheme**: Sales data in green, Purchase data in blue
- **Smooth Animations**: Multiple animation controllers for different effects
- **Modern UI**: Card-based layout with shadows and gradients
- **Responsive Design**: Adapts to different screen sizes

### 📊 **Graph Components**
1. **Animated Line Charts**: 
   - Sales trend line (Green)
   - Purchase trend line (Blue)
   - Smooth drawing animation
   - Interactive data points

2. **Header Cards**:
   - Total Sales summary
   - Total Purchase summary
   - Pulse animation effects
   - Modern card design

3. **Performance Indicators**:
   - Growth rate display
   - Profit margin metrics
   - Color-coded performance indicators

4. **Monthly Breakdown**:
   - Detailed monthly data
   - Visual progress bars
   - Sales vs Purchase comparison

### 🎭 **Animations**
- **Fade Animation**: Screen entrance effect
- **Scale Animation**: Card entrance with bounce
- **Pulse Animation**: Continuous highlight effect
- **Graph Drawing**: Line drawing with easing curves
- **Refresh Animation**: Replay all animations

### 🧭 **Navigation**
- Added to main app drawer under "Analytics Section"
- Accessible via: Drawer → Sales & Purchase Analytics
- Route: `/AnimatedGraphs`

## Technical Implementation

### **Animation Controllers**
```dart
- _animationController: Main graph drawing (2.5s)
- _fadeController: Screen fade-in (1.5s)  
- _pulseController: Continuous pulse effect (2s loop)
```

### **Custom Painter**
- `AnimatedGraphPainter`: Custom canvas drawing
- Grid lines, data points, and smooth line rendering
- Animation interpolation for smooth transitions

### **Data Structure**
```dart
List<Map<String, dynamic>> salesData = [
  {'month': 'Jan', 'sales': 12000, 'purchase': 8000},
  // ... more data
];
```

## Usage

1. **Open the app drawer**
2. **Navigate to "Sales & Purchase Analytics"**
3. **View the animated graphs**
4. **Tap refresh icon to replay animations**
5. **Scroll to see monthly breakdown**

## Customization

The screen can be easily customized by:
- Modifying color schemes in the `salesColor` and `purchaseColor` variables
- Adjusting animation durations in the controller definitions
- Adding more data points to the `salesData` list
- Customizing the UI components and layouts

## Future Enhancements

- Real-time data integration
- Interactive data point selection
- Export functionality
- Additional chart types (bar, pie, etc.)
- Date range filtering
- Data export to PDF/Excel
