#!/bin/bash

# Script to add tvOS target to the Simple Calendar Xcode project
# Run this from the project root directory

echo "Adding tvOS target to Simple Calendar project..."

# Note: This script provides instructions for adding tvOS target manually
# since programmatically modifying .pbxproj files is complex and error-prone

echo ""
echo "To add tvOS support to your Xcode project:"
echo ""
echo "1. Open Simple Calendar.xcodeproj in Xcode"
echo "2. Select the project in the Project Navigator"
echo "3. Click the '+' button at the bottom of the target list"
echo "4. Choose 'tvOS App' from the template selection"
echo "5. Configure the new target:"
echo "   - Product Name: Simple Calendar"
echo "   - Organization Identifier: com.nathanfennel"
echo "   - Bundle Identifier: com.nathanfennel.simplecalendar"
echo "   - Language: SwiftUI"
echo "   - Uncheck 'Include Tests' (since you already have tests)"
echo ""
echo "6. After creating the target, update its Info.plist:"
echo "   - Replace the contents with the Info.tvOS.plist file"
echo "   - Or copy the relevant entries from Info.tvOS.plist"
echo ""
echo "7. Add the Swift files to the tvOS target:"
echo "   - Select all .swift files in the Simple Calendar group"
echo "   - In the File Inspector, check the box for the tvOS target"
echo ""
echo "8. Add necessary frameworks:"
echo "   - SwiftUI, Combine, SwiftData, MapKit, EventKit, etc."
echo ""
echo "9. Build and test the tvOS target"
echo ""

echo "The code has been updated to support tvOS with:"
echo "- Platform-specific image handling"
echo "- tvOS-optimized UI layouts and focus navigation"
echo "- Larger fonts and touch targets for TV viewing"
echo "- Disabled features that don't work well on TV (maps)"
echo "- Proper scene structure for tvOS"


