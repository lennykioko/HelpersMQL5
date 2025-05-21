//+------------------------------------------------------------------+
//|                                                     GetRange.mqh |
//|                                             Copyright 2025       |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Get the range of the current symbol                              |
//+------------------------------------------------------------------+

// Structure to hold range information
struct TimeRange {
    double high;           // High of the range
    double low;            // Low of the range
    double middle;         // Middle of the range
    double openPrice;      // Open price of the range
    double closePrice;     // Close price of the range
    double diffHighLow;    // Difference between high and low
    string type;           // Type: "Bullish" or "Bearish"
    bool valid;            // Whether the range is valid
    datetime startTime;    // Start time of the range
    datetime endTime;      // End time of the range
    int startBarIndex;     // Index of the first bar in the range
    int endBarIndex;       // Index of the last bar in the range
};

// Function to draw vertical lines and dots on chart
void DrawRangeOnChart(TimeRange &range, string name, color lineColor=clrBlue, color highColor=clrGreen, color lowColor=clrRed, ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT) {
    // Draw vertical lines for range start and end times
    string startLineName = name + "Start";
    string endLineName = name + "End";
    string highDotName = name + "High";
    string lowDotName = name + "Low";

    ObjectDelete(0, startLineName);
    ObjectDelete(0, endLineName);
    ObjectDelete(0, highDotName);
    ObjectDelete(0, lowDotName);

    // Create vertical lines
    ObjectCreate(0, startLineName, OBJ_VLINE, 0, range.startTime, 0);
    ObjectSetInteger(0, startLineName, OBJPROP_COLOR, lineColor);
    ObjectSetInteger(0, startLineName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, startLineName, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetString(0, startLineName, OBJPROP_TOOLTIP,
        "Range Details:\n" +
        "T " + range.type + "\n" +
        "S: " + TimeToString(range.startTime, TIME_DATE|TIME_MINUTES) + "\n" +
        "E: " + TimeToString(range.endTime, TIME_DATE|TIME_MINUTES) + "\n" +
        "Hi: " + DoubleToString(range.high, _Digits) + "\n" +
        "Lo: " + DoubleToString(range.low, _Digits) + "\n" +
        "Mi: " + DoubleToString(range.middle, _Digits) + "\n" +
        "Op: " + DoubleToString(range.openPrice, _Digits) + "\n" +
        "Cl: " + DoubleToString(range.closePrice, _Digits) + "\n" +
        "Sz: " + DoubleToString(range.diffHighLow, 2) + "\n" +
        "St: " + IntegerToString(range.startBarIndex) + "\n" +
        "En: " + IntegerToString(range.endBarIndex)
    );

    ObjectCreate(0, endLineName, OBJ_VLINE, 0, range.endTime, 0);
    ObjectSetInteger(0, endLineName, OBJPROP_COLOR, lineColor);
    ObjectSetInteger(0, endLineName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, endLineName, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetString(0, endLineName, OBJPROP_TOOLTIP, "Range End: " + TimeToString(range.endTime) + "\n(See Range Start line for full details)");

    // Create dots at high and low points
    if(range.valid) {
        // Find bar index closest to the high and low prices during the range
        datetime highTime = range.startTime;
        datetime lowTime = range.startTime;

        int bars = Bars(_Symbol, timeframe);
        // First find the range of indices
        int oldestBarIndex = -1;
        int newestBarIndex = -1;

        for(int i = bars-1; i >= 0 && i < bars; i--) {
            datetime barTime = iTime(_Symbol, timeframe, i);

            if(barTime >= range.startTime && barTime <= range.endTime) {
                if(oldestBarIndex == -1) oldestBarIndex = i;
                newestBarIndex = i;
            }

            if(barTime < range.startTime && oldestBarIndex != -1)
                break;
        }

        // Search in chronological order
        if(oldestBarIndex != -1 && newestBarIndex != -1) {
            for(int i = oldestBarIndex; i >= newestBarIndex; i--) {
                datetime barTime = iTime(_Symbol, timeframe, i);

                if(barTime < range.startTime || barTime > range.endTime) continue;

                double high = iHigh(_Symbol, timeframe, i);
                double low = iLow(_Symbol, timeframe, i);

                if(high == range.high) highTime = barTime;
                if(low == range.low) lowTime = barTime;
            }
        }

        // Draw dots
        ObjectCreate(0, highDotName, OBJ_ARROW, 0, highTime, range.high);
        ObjectSetInteger(0, highDotName, OBJPROP_ARROWCODE, 159); // Down arrow
        ObjectSetInteger(0, highDotName, OBJPROP_COLOR, highColor);
        ObjectSetInteger(0, highDotName, OBJPROP_WIDTH, 2);
        ObjectSetString(0, highDotName, OBJPROP_TOOLTIP, "Range High: " + DoubleToString(range.high, _Digits));

        ObjectCreate(0, lowDotName, OBJ_ARROW, 0, lowTime, range.low);
        ObjectSetInteger(0, lowDotName, OBJPROP_ARROWCODE, 159); // Down arrow
        ObjectSetInteger(0, lowDotName, OBJPROP_COLOR, lowColor);
        ObjectSetInteger(0, lowDotName, OBJPROP_WIDTH, 2);
        ObjectSetString(0, lowDotName, OBJPROP_TOOLTIP, "Range Low: " + DoubleToString(range.low, _Digits));
    }

    ChartRedraw(0);
}

// Draw extended horizontal levels for high, low, and middle
void DrawRangeLevels(TimeRange &range, string name, bool isRecentRange=false, ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT,
                     bool drawHigh=true, bool drawLow=true, bool drawMiddle=true,
                     color highColor=clrGreen, color lowColor=clrRed, color midColor=clrGoldenrod) {
    if(!range.valid) return;

    string highLevelName = name + "HighLevel";
    string lowLevelName = name + "LowLevel";
    string midLevelName = name + "MidLevel";

    // Delete any existing levels
    ObjectDelete(0, highLevelName);
    ObjectDelete(0, lowLevelName);
    ObjectDelete(0, midLevelName);

    // Get current time to extend lines to right edge of chart
    datetime currentTime = TimeCurrent();

    // Get chart width for extending the lines
    datetime futureTime = currentTime + (86400 * 5); // Extend 5 days into future

    // Create horizontal line for the high
    if(drawHigh) {
        ObjectCreate(0, highLevelName, OBJ_TREND, 0, range.startTime, range.high, futureTime, range.high);
        ObjectSetInteger(0, highLevelName, OBJPROP_COLOR, highColor);
        ObjectSetInteger(0, highLevelName, OBJPROP_WIDTH, isRecentRange ? 2 : 1);
        ObjectSetInteger(0, highLevelName, OBJPROP_STYLE, isRecentRange ? STYLE_SOLID : STYLE_DOT);
        ObjectSetInteger(0, highLevelName, OBJPROP_RAY_RIGHT, true); // Extend to the right
        ObjectSetString(0, highLevelName, OBJPROP_TOOLTIP, "Range High: " + DoubleToString(range.high, _Digits));
    }

    // Create horizontal line for the low
    if(drawLow) {
        ObjectCreate(0, lowLevelName, OBJ_TREND, 0, range.startTime, range.low, futureTime, range.low);
        ObjectSetInteger(0, lowLevelName, OBJPROP_COLOR, lowColor);
        ObjectSetInteger(0, lowLevelName, OBJPROP_WIDTH, isRecentRange ? 2 : 1);
        ObjectSetInteger(0, lowLevelName, OBJPROP_STYLE, isRecentRange ? STYLE_SOLID : STYLE_DOT);
        ObjectSetInteger(0, lowLevelName, OBJPROP_RAY_RIGHT, true); // Extend to the right
        ObjectSetString(0, lowLevelName, OBJPROP_TOOLTIP, "Range Low: " + DoubleToString(range.low, _Digits));
    }

    // Create horizontal line for the middle
    if(drawMiddle) {
        ObjectCreate(0, midLevelName, OBJ_TREND, 0, range.startTime, range.middle, futureTime, range.middle);
        ObjectSetInteger(0, midLevelName, OBJPROP_COLOR, midColor);
        ObjectSetInteger(0, midLevelName, OBJPROP_WIDTH, isRecentRange ? 2 : 1);
        ObjectSetInteger(0, midLevelName, OBJPROP_STYLE, isRecentRange ? STYLE_DASH : STYLE_DOT);
        ObjectSetInteger(0, midLevelName, OBJPROP_RAY_RIGHT, true); // Extend to the right
        ObjectSetString(0, midLevelName, OBJPROP_TOOLTIP, "Range Middle: " + DoubleToString(range.middle, _Digits));
    }

    // Add range type and size label if it's the recent range
    if(isRecentRange) {
        string labelName = name + "Label";
        ObjectDelete(0, labelName);

        // Create a text label
        ObjectCreate(0, labelName, OBJ_TEXT, 0, range.endTime, range.high + (10 * _Point));
        ObjectSetString(0, labelName, OBJPROP_TEXT,
                        range.type + " Range: " + DoubleToString(range.diffHighLow / _Point, 1) + " pts");
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, range.type == "Bullish" ? clrLime : clrRed);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
    }

    ChartRedraw(0);
}

// Calculate range between two times for a specific day offset
TimeRange CalculateRangeForDay(string startTimeStr, string endTimeStr, int dayOffset, string name="Range",
                               bool drawOnChart=false, ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT,
                               bool drawHigh=true, bool drawLow=true, bool drawMiddle=true) {
    TimeRange range;
    range.high = 0;
    range.low = DBL_MAX;
    range.openPrice = 0;
    range.closePrice = 0;
    range.middle = 0;
    range.diffHighLow = 0;
    range.type = "";
    range.valid = false;
    range.startBarIndex = -1;
    range.endBarIndex = -1;

    // Get current time
    datetime now = TimeCurrent();
    MqlDateTime dtNow;
    TimeToStruct(now, dtNow);

    // Create date for the requested day offset
    MqlDateTime dtTarget = dtNow;
    dtTarget.hour = 0;
    dtTarget.min = 0;
    dtTarget.sec = 0;

    // Adjust for the requested day offset
    datetime targetDate = StructToTime(dtTarget) - dayOffset * 86400; // 86400 seconds = 1 day
    TimeToStruct(targetDate, dtTarget);

    // Parse start time
    int startHour = (int)StringToInteger(StringSubstr(startTimeStr, 0, 2));
    int startMinute = (int)StringToInteger(StringSubstr(startTimeStr, 3, 2));

    // Parse end time
    int endHour = (int)StringToInteger(StringSubstr(endTimeStr, 0, 2));
    int endMinute = (int)StringToInteger(StringSubstr(endTimeStr, 3, 2));

    // Create datetime objects for start and end times for the target day
    MqlDateTime startDt = dtTarget;
    startDt.hour = startHour;
    startDt.min = startMinute;
    startDt.sec = 0;

    MqlDateTime endDt = dtTarget;
    endDt.hour = endHour;
    endDt.min = endMinute;
    endDt.sec = 0;

    range.startTime = StructToTime(startDt);
    range.endTime = StructToTime(endDt);

    // Check if current time is before the end time and we're requesting today's range
    if(dayOffset == 0 && now < range.endTime) {
        Print("Current time is before the range end time. Cannot calculate complete range yet.");
        return range; // Return invalid range
    }

    // Search bars for the range
    int totalBars = Bars(_Symbol, timeframe);
    int barsProcessed = 0;
    bool foundFirstBar = false;
    double firstBarOpen = 0;
    double lastBarClose = 0;
    int firstBarIndex = -1;

    // First pass: find the index range of bars that fall within our time range
    int oldestBarIndex = -1;
    int newestBarIndex = -1;

    for(int i = totalBars-1; i >= 0 && i < totalBars; i--) {
        datetime barTime = iTime(_Symbol, timeframe, i);

        // Found a bar within our range
        if(barTime >= range.startTime && barTime <= range.endTime) {
            if(oldestBarIndex == -1) oldestBarIndex = i;
            newestBarIndex = i;
        }

        // If we've passed the end time, we can stop searching
        if(barTime < range.startTime && oldestBarIndex != -1)
            break;
    }

    // Now process the bars in chronological order (oldest to newest)
    if(oldestBarIndex != -1 && newestBarIndex != -1) {
        for(int i = oldestBarIndex; i >= newestBarIndex; i--) {
            datetime barTime = iTime(_Symbol, timeframe, i);

            // Double-check that bar is within our range
            if(barTime < range.startTime || barTime > range.endTime) continue;

            // Bar is within our range
            double high = iHigh(_Symbol, timeframe, i);
            double low = iLow(_Symbol, timeframe, i);
            double open = iOpen(_Symbol, timeframe, i);
            double close = iClose(_Symbol, timeframe, i);

            // Store first (oldest) bar's open price
            if(!foundFirstBar) {
                firstBarOpen = open;
                foundFirstBar = true;
                firstBarIndex = i;
            }

            // Update last (newest) bar's close price
            lastBarClose = close;

            // Update range high and low
            if(high > range.high) range.high = high;
            if(low < range.low) range.low = low;

            barsProcessed++;
        }
    }

    // If we found any bars
    if(barsProcessed > 0 && range.low != DBL_MAX) {
        range.valid = true;
        range.openPrice = firstBarOpen;
        range.closePrice = lastBarClose;
        range.middle = (range.high + range.low) / 2.0;
        range.diffHighLow = range.high - range.low;
        range.type = (range.closePrice >= range.openPrice) ? "Bullish" : "Bearish";
        range.startBarIndex = oldestBarIndex;
        range.endBarIndex = newestBarIndex;

        // Draw on chart if requested
        if(drawOnChart) {
            string rangeName = name + "_" + IntegerToString(dayOffset);
            DrawRangeOnChart(range, rangeName, clrBlue, clrGreen, clrRed, timeframe);

            // Only draw horizontal levels for today's range (dayOffset = 0)
            if(dayOffset == 0) {
                DrawRangeLevels(range, rangeName, true, timeframe,
                                drawHigh, drawLow, drawMiddle,
                                clrGreen, clrRed, clrGoldenrod);
            }
        }
    } else {
        Print("No bars found within the specified time range for day offset: ", dayOffset);
    }

    return range;
}

// Get an array of ranges for multiple days
bool GetRanges(string startTimeStr, string endTimeStr, TimeRange &rangeArray[], int daysBack=0,
               string name="Range", bool drawOnChart=false, ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT,
               bool drawHigh=true, bool drawLow=true, bool drawMiddle=true) {
    // Resize the array to fit the requested number of days
    ArrayResize(rangeArray, daysBack + 1);
    bool hasValidRanges = false;

    // Calculate ranges for each day
    for(int i = 0; i <= daysBack; i++) {
        rangeArray[i] = CalculateRangeForDay(startTimeStr, endTimeStr, i, name + IntegerToString(i),
                                            drawOnChart, timeframe, drawHigh, drawLow, drawMiddle);
        if(rangeArray[i].valid) hasValidRanges = true;
    }

    return hasValidRanges;
}
