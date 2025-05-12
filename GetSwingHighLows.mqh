//+------------------------------------------------------------------+
//|                                             GetSwingHighLows.mqh |
//|                                             Copyright 2025       |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Get the swing highs and lows for the current symbol               |
//+------------------------------------------------------------------+

//--- Swing point structure to store key information
struct SwingPoint {
    int       bar;           // Bar index
    double    price;         // Price level
    bool      taken;         // Whether it's been taken out
    datetime  time;          // Time of the swing point
};

//+------------------------------------------------------------------+
//| Helper function to plot swing points on chart                     |
//+------------------------------------------------------------------+
void PlotSwingPoints(SwingPoint &points[], string prefix, color pointColor, bool isHighPoint = false) {
    // Check if there are any points to plot
    if(ArraySize(points) <= 0)
        return;

    long chartId = ChartID();
    int window = 0; // Main chart window

    for(int i = 0; i < ArraySize(points); i++) {
        // Include taken status and time in the name for uniqueness
        string takenStatus = points[i].taken ? "_taken" : "_active";
        string timeStr = TimeToString(points[i].time, TIME_DATE|TIME_MINUTES);
        string name = prefix + "_" + IntegerToString(i) + takenStatus + "_" + timeStr;
        string dot = name;

        // Delete existing object if it exists
        ObjectDelete(chartId, dot);

        // Create new object
        if(!ObjectCreate(chartId, dot, OBJ_ARROW, window, points[i].time, points[i].price)) {
            Print("Error creating swing point dot: ", GetLastError());
            continue;
        }

        // Use different appearance for taken vs active points
        if(points[i].taken) {
            // For taken points, use a different arrow and color
            ObjectSetInteger(chartId, dot, OBJPROP_ARROWCODE, 251); // Different arrow shape (empty diamond)

            // Use another predefined color for taken points instead of calculating it
            color takenColor;
            switch(pointColor) {
                case clrCrimson:    takenColor = clrLightPink;   break;
                case clrDodgerBlue: takenColor = clrLightBlue;   break;
                case clrGreen:      takenColor = clrLightGreen;  break;
                case clrOrange:     takenColor = clrLightYellow; break;
                case clrGold:       takenColor = clrLightYellow; break;
                case clrPurple:     takenColor = clrViolet;      break;
                default:            takenColor = clrSilver;      break;
            }

            ObjectSetInteger(chartId, dot, OBJPROP_COLOR, takenColor);
            ObjectSetInteger(chartId, dot, OBJPROP_WIDTH, 1);   // Thinner
        } else {
            // For active points, use normal appearance
            ObjectSetInteger(chartId, dot, OBJPROP_ARROWCODE, 159); // Filled circle
            ObjectSetInteger(chartId, dot, OBJPROP_COLOR, pointColor);
            ObjectSetInteger(chartId, dot, OBJPROP_WIDTH, 2);   // Thicker
        }

        // Position correctly based on whether it's a high or low point
        if(isHighPoint) {
            // For high points, position the dot above the candle
            ObjectSetInteger(chartId, dot, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
        } else {
            // For low points, position the dot below the candle
            ObjectSetInteger(chartId, dot, OBJPROP_ANCHOR, ANCHOR_TOP);
        }
    }
}

//+------------------------------------------------------------------+
//| Function to find swing lows on the chart                          |
//+------------------------------------------------------------------+
void GetSwingLows(
    int count,                                // Number of swing lows to find
    SwingPoint &output[],                     // Output array
    ENUM_TIMEFRAMES period = PERIOD_CURRENT,  // Timeframe
    int maxBarsToAnalyze = 100,               // Maximum bars to look back
    bool plotDots = false,                    // Whether to plot the points
    color dotColor = clrCrimson               // Color for the dots
) {
    // Validate input
    if(count <= 0) {
        Print("Invalid count for swing lows: ", count);
        return;
    }

    // Initialize output array
    ArrayResize(output, 0);

    int found = 0;
    int totalBars = Bars(_Symbol, period);
    int i = 2; // Start from bar 2 to ensure candle 0 is not involved

    // Main loop to find swing lows
    while(found < count && i < totalBars - 1 && i < maxBarsToAnalyze) {
        double prevLow = iLow(_Symbol, period, i + 1);
        double currLow = iLow(_Symbol, period, i);
        double nextLow = iLow(_Symbol, period, i - 1);

        // Check if this is a swing low point
        if(currLow < prevLow && currLow < nextLow) {
            SwingPoint swing;
            swing.bar = i;
            swing.price = currLow;
            swing.taken = false;
            swing.time = iTime(_Symbol, period, i);

            // Check if this swing low has been taken out
            for(int j = i - 1; j >= 0; j--) {
                double futureLow = iLow(_Symbol, period, j);
                if(futureLow < currLow) {
                    swing.taken = true;
                    break;
                }
            }

            // Add to output array
            int newSize = found + 1;
            ArrayResize(output, newSize);
            output[found] = swing;
            found++;
        }
        i++;
    }

    // Plot swing lows if requested
    if(plotDots && ArraySize(output) > 0) {
        PlotSwingPoints(output, "SwLow", dotColor, false); // false = low point
    }
}

//+------------------------------------------------------------------+
//| Function to find swing highs on the chart                         |
//+------------------------------------------------------------------+
void GetSwingHighs(
    int count,                                // Number of swing highs to find
    SwingPoint &output[],                     // Output array
    ENUM_TIMEFRAMES period = PERIOD_CURRENT,  // Timeframe
    int maxBarsToAnalyze = 100,               // Maximum bars to look back
    bool plotDots = false,                    // Whether to plot the points
    color dotColor = clrDodgerBlue            // Color for the dots
) {
    // Validate input
    if(count <= 0) {
        Print("Invalid count for swing highs: ", count);
        return;
    }

    // Initialize output array
    ArrayResize(output, 0);

    int found = 0;
    int totalBars = Bars(_Symbol, period);
    int i = 2; // Start from bar 2 to ensure candle 0 is not involved

    // Main loop to find swing highs
    while(found < count && i < totalBars - 1 && i < maxBarsToAnalyze) {
        double prevHigh = iHigh(_Symbol, period, i + 1);
        double currHigh = iHigh(_Symbol, period, i);
        double nextHigh = iHigh(_Symbol, period, i - 1);

        // Check if this is a swing high point
        if(currHigh > prevHigh && currHigh > nextHigh) {
            SwingPoint swing;
            swing.bar = i;
            swing.price = currHigh;
            swing.taken = false;
            swing.time = iTime(_Symbol, period, i);

            // Check if this swing high has been taken out
            for(int j = i - 1; j >= 0; j--) {
                double futureHigh = iHigh(_Symbol, period, j);
                if(futureHigh > currHigh) {
                    swing.taken = true;
                    break;
                }
            }

            // Add to output array
            int newSize = found + 1;
            ArrayResize(output, newSize);
            output[found] = swing;
            found++;
        }
        i++;
    }

    // Plot swing highs if requested
    if(plotDots && ArraySize(output) > 0) {
        PlotSwingPoints(output, "SwHigh", dotColor, true); // true = high point
    }
}


