bool CheckIsAboveSMA(double price, int maDuration = 20, ENUM_TIMEFRAMES period = PERIOD_CURRENT, string symbol = NULL, bool verbose = false) {
    if(symbol == NULL) symbol = _Symbol;
    double maArray[];
    // int ma20Handle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_SMA, PRICE_CLOSE);
    int maHandle = iMA(symbol, period, maDuration, 0, MODE_SMA, PRICE_CLOSE);

    if (maHandle == INVALID_HANDLE) {
        Print("Error creating MA handles: ", GetLastError());
        return false;
    }

    // Copy MA values
    if (CopyBuffer(maHandle, 0, 0, 1, maArray) <= 0) {
        Print("Error copying MA values: ", GetLastError());
        return false;
    }

    // Release handles
    IndicatorRelease(maHandle);

    if(verbose) {
        Print("price: " + DoubleToString(price) + " MA value: " +  DoubleToString(maArray[0]) + " price > MA: " + (price > maArray[0] ? "true" : "false"));
    }

    return (price > maArray[0]);
}
