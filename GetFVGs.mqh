//+------------------------------------------------------------------+
//|                                             GetFVGs.mqh          |
//|                                             Copyright 2025       |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

struct FVG {
    bool exists;       // Whether FVG exists
    bool isFilled;     // Whether FVG is filled
    double high;       // Top of gap
    double low;        // Bottom of gap
    double midpoint;   // Midpoint of gap
    double gapSize;     // Size of the gap
    int bar;           // Bar index where FVG was detected
    datetime time;     // Time of the FVG
};

void GetBullishFVGs(int startBar, int endBar, FVG &bullishFVGs[], int minFVGSearchRange = 10, bool plotFVGs = false, color fvgColor = clrGreenYellow, ENUM_TIMEFRAMES period = PERIOD_CURRENT, string symbol = NULL, bool verbose = false) {
    if(symbol == NULL) symbol = _Symbol;
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    ArrayResize(bullishFVGs, 0);
    int found = 0;

    // Validate inputs
    if(startBar < 0 || endBar < 0) {
        return;
    }

    // Ensure we're searching across a range
    if(startBar == endBar) {
        // If we get same bar, create a search range
        endBar = startBar + minFVGSearchRange;
    }

    // Adjust if provided in wrong order (we need startBar < endBar for the loop)
    if(startBar > endBar) {
        int temp = startBar;
        startBar = endBar;
        endBar = temp;
    }

    // Make sure we're not exceeding available bars
    int totalBars = Bars(symbol, period);
    if(totalBars < 3) {
        // Not enough bars to analyze for FVG
        return;
    }

    int maxBars = totalBars - 2;
    if(endBar >= maxBars) endBar = maxBars - 1;

    if(verbose) {
        Print("[", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), "] Searching for FVG between start bar: ", startBar, " and end bar: ", endBar);
    }


    for(int i = startBar; i <= endBar && i < maxBars; i++) {
        // Ensure we have at least 3 bars to analyze
        if(i + 1 >= maxBars || i - 1 < 0) continue;

        double leftHigh = iHigh(symbol, period, i + 1);
        double middleHigh = iHigh(symbol, period, i); // can be used later
        double middleLow = iLow(symbol, period, i); // can be used later
        double rightLow = iLow(symbol, period, i - 1);

        // Check if there's a gap
        if(rightLow > leftHigh) {
            FVG result;
            result.exists = true;
            result.isFilled = false;
            result.high = rightLow;
            result.low = leftHigh;
            result.midpoint = NormalizeDouble((result.low + result.high) / 2, digits);
            result.gapSize = MathAbs(rightLow - leftHigh);
            result.bar = i;
            result.time = iTime(symbol, period, i);

            // Start checking from the bar after FVG formation
            for(int j = i - 1; j >= 0; j--) {
                double closePrice = iClose(symbol, period, j);

                // If any closing price is below the FVG's low, the gap is filled
                if(closePrice < result.low) {
                    result.isFilled = true;
                    break;
                }
            }

            int newSize = found + 1;
            ArrayResize(bullishFVGs, newSize);
            bullishFVGs[found] = result;
            found++;

            if(verbose) {
                Print("[", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), "] Bullish FVG found at bar ", i,
                    " High=", DoubleToString(result.high, digits),
                    " Low=", DoubleToString(result.low, digits),
                    " Midpoint=", DoubleToString(result.midpoint, digits),
                    " GapSize=", DoubleToString(result.gapSize, digits),
                    " Time=", TimeToString(result.time, TIME_DATE|TIME_SECONDS));
            }
        }
    }

    if(found == 0) {
        if(verbose) {
            Print("[", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), "] No Bullish FVG found between start bar: ", startBar, " and end bar: ", endBar);
        }
    }

    if(plotFVGs && ArraySize(bullishFVGs) > 0) {
        PlotFVGs(bullishFVGs, fvgColor, true);
    }
}

void GetBearishFVGs(int startBar, int endBar, FVG &bearishFVGs[], int minFVGSearchRange = 10, bool plotFVGs = false, color fvgColor = clrDeepPink, ENUM_TIMEFRAMES period = PERIOD_CURRENT, string symbol = NULL, bool verbose = false) {
    if(symbol == NULL) symbol = _Symbol;
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    ArrayResize(bearishFVGs, 0);
    int found = 0;

    // Validate inputs
    if(startBar < 0 || endBar < 0) {
        return;
    }

    // Ensure we're searching across a range
    if(startBar == endBar) {
        // If we get same bar, create a search range
        endBar = startBar + minFVGSearchRange;
    }

    // Adjust if provided in wrong order (we need startBar < endBar for the loop)
    if(startBar > endBar) {
        int temp = startBar;
        startBar = endBar;
        endBar = temp;
    }

    // Make sure we're not exceeding available bars
    int totalBars = Bars(symbol, period);
    if(totalBars < 3) {
        // Not enough bars to analyze for FVG
        return;
    }

    int maxBars = totalBars - 2;
    if(endBar >= maxBars) endBar = maxBars - 1;

    if(verbose) {
        Print("[", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), "] Searching for FVG between start bar: ", startBar, " and end bar: ", endBar);
    }

    for(int i = startBar; i <= endBar && i < maxBars; i++) {
        // Ensure we have at least 3 bars to analyze
        if(i + 1 >= maxBars || i - 1 < 0) continue;

        double leftLow = iLow(symbol, period, i + 1);
        double middleHigh = iHigh(symbol, period, i); // can be used later
        double middleLow = iLow(symbol, period, i); // can be used later
        double rightHigh = iHigh(symbol, period, i - 1);

        // Check if there's a gap
        if(leftLow > rightHigh) {
            FVG result;
            result.exists = true;
            result.isFilled = false;
            result.high = rightHigh;
            result.low = leftLow;
            result.midpoint = NormalizeDouble((result.low + result.high) / 2, digits);
            result.gapSize = MathAbs(leftLow - rightHigh);
            result.bar = i;
            result.time = iTime(symbol, period, i);

            // Start checking from the bar after FVG formation
            for(int j = i - 1; j >= 0; j--) {
                double closePrice = iClose(symbol, period, j);

                // If any closing price is above the FVG's low, the gap is filled
                if(closePrice > result.low) {
                    result.isFilled = true;
                    break;
                }
            }

            int newSize = found + 1;
            ArrayResize(bearishFVGs, newSize);
            bearishFVGs[found] = result;
            found++;

            if(verbose) {
                Print("[", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), "] Bearish FVG found at bar ", i,
                    " High=", DoubleToString(result.high, digits),
                    " Low=", DoubleToString(result.low, digits),
                    " Midpoint=", DoubleToString(result.midpoint, digits),
                    " GapSize=", DoubleToString(result.gapSize, digits),
                    " Time=", TimeToString(result.time, TIME_DATE|TIME_SECONDS));
            }
        }
    }

    if(found == 0) {
        if(verbose) {
            Print("[", TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), "] No Bearish FVG found between start bar: ", startBar, " and end bar: ", endBar);
        }
    }

    if(plotFVGs && ArraySize(bearishFVGs) > 0) {
        PlotFVGs(bearishFVGs, fvgColor, false);
    }
}

void PlotFVGs(FVG &fvgs[], color fvgColor = clrDodgerBlue, bool isBullish = true) {
    // Check if there are any FVGs to plot
    if(ArraySize(fvgs) <= 0) return;
    string prefix = isBullish ? "B-FVG" : "S-FVG";

    long chartId = ChartID();
    int window = 0; // Main chart window

    for(int i = 0; i < ArraySize(fvgs); i++) {
        if(fvgs[i].exists) {
            string name = prefix + "_i_" + IntegerToString(i);

            if(fvgs[i].isFilled) {
                HighlightBar(name, fvgs[i].time, fvgs[i].high, fvgs[i].low, fvgColor, 3);

            } else {
                HighlightBar(name, fvgs[i].time, fvgs[i].high, fvgs[i].low, fvgColor, 11);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Draw a rectangle to highlight a bar                              |
//+------------------------------------------------------------------+

void HighlightBar(string name, datetime time, double high, double low, color clr, int size = 10, ENUM_TIMEFRAMES period = PERIOD_CURRENT) {
    // Check if the object already exists and delete it if it does
    // This ensures that we don't create multiple objects with the same name
    // and that we can update the rectangle's position and size if needed

    string objName = name;
    if(ObjectFind(0, objName) >= 0) ObjectDelete(0, objName);

    // Calculate the next bar's time for the rectangle's right edge
    datetime nextBarTime = time + (PeriodSeconds(period) * size);

    if(!ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time, high, nextBarTime, low)) {
        Print("Error creating rectangle: ", GetLastError());
        return;
    }

    // Set the properties of the rectangle
    ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, objName, OBJPROP_FILL, false);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetInteger(0, objName, OBJPROP_BACK, true);  // Place in the background
    ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+