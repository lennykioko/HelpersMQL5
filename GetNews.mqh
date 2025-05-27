//+------------------------------------------------------------------+
//|                                             GetNews.mqh          |
//|                                             Copyright 2025       |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

bool IsTradingAllowedByNews() {
    string code = "US";
    MqlCalendarValue values[];
    datetime currentTime = TimeCurrent();
    datetime tomorrow = currentTime + 24 * 3600; // Add 24 hours

    // Check events from now until tomorrow end of day
    datetime dateTo = tomorrow + 24 * 3600;

    if(CalendarValueHistory(values, currentTime, dateTo, code)) {
        for(int i = 0; i < ArraySize(values); i++) {
            MqlCalendarEvent event;
            ulong eventId = values[i].event_id;

            if(CalendarEventById(eventId, event)) {
                datetime eventTime = values[i].time;

                // Check for bank holidays today
                if(event.type == CALENDAR_TYPE_HOLIDAY &&
                   TimeToString(eventTime, TIME_DATE) == TimeToString(currentTime, TIME_DATE)) {
                    Print("Trading not allowed: Bank Holiday today");
                    return false;
                }

                // Check for NFP tomorrow
                if(event.name == "Nonfarm Payrolls" &&
                   TimeToString(eventTime, TIME_DATE) == TimeToString(tomorrow, TIME_DATE)) {
                    if(currentTime < eventTime) {
                        Print("Trading not allowed: NFP tomorrow");
                        return false;
                    }
                }

                // Check for CPI today
                if(StringFind(event.name, "CPI") >= 0 &&
                   TimeToString(eventTime, TIME_DATE) == TimeToString(currentTime, TIME_DATE)) {
                    if(currentTime < eventTime) {
                        Print("Trading not allowed: CPI today");
                        return false;
                    }
                }
            } else {
                Print("Error retrieving event by ID: " + IntegerToString(GetLastError()));
            }
        }
    } else {
        Print("Error retrieving news values: " + IntegerToString(GetLastError()));
        return false; // If we can't check the news, better not to trade
    }

    return true; // No blocking news events found
}

//+------------------------------------------------------------------+