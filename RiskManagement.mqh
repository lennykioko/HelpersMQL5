//+------------------------------------------------------------------+
//|                                             RiskManagement.mqh   |
//|                                             Copyright 2025       |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

bool CheckMaxDailyLossExceeded(const double startDayBalance, const double maxDailyLoss) {
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double loss = startDayBalance - currentBalance;

    if(loss >= maxDailyLoss) {
        Print("Max daily loss exceeded: ", DoubleToString(loss, 2));
        return true;
    }
    return false;
}

bool CheckDailyTargetReached(const double startDayBalance, const double dailyTarget) {
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double profit = currentBalance - startDayBalance;

    if(profit >= dailyTarget) {
        Print("Daily target reached: ", DoubleToString(profit, 2));
        return true;
    }
    return false;
}

void ResetDayBalance(double &startDayBalance, datetime &lastReset) {
    datetime now = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(now, dt);

    // Reset at midnight
    if(dt.hour == 0 && lastReset != dt.day) {
        startDayBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        Print("Starting Day balance reset to: ", DoubleToString(startDayBalance, 2) + " at " + TimeToString(now, TIME_DATE | TIME_MINUTES) + "lastReset: " + TimeToString(lastReset, TIME_DATE | TIME_MINUTES));
    }
}
