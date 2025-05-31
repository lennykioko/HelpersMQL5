//+------------------------------------------------------------------+
//|                                              OrderManagement.mqh |
//|                                             Copyright 2025       |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict
#include <Trade/Trade.mqh>
CTrade trade;

double GetPipValue(string symbol = NULL) {
    if(symbol == NULL) symbol = _Symbol;
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

    if(digits == 5 || digits == 3) {
        return point * 10;
    } else if(digits == 2 || digits == 4) {
        return point;
    } else if(digits == 1) {
        return 1.0;
    } else {
        return 0.0; // Invalid digit count
    }
}

double CalculateLotSize(double riskDollars, double entryPrice, double slPrice, bool verbose = false) {

    if(entryPrice == slPrice)
        return 0;

    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double ticksPerPip = 10;
    double pipValue = NormalizeDouble(tickSize * ticksPerPip, 5);

    double pips = MathAbs(entryPrice - slPrice) / GetPipValue();

    if(pips <= 0)
        return 0;

    // Calculate lot size based on risk
    double lotSize = NormalizeDouble(riskDollars / (pips * pipValue), 2);

    // Apply symbol constraints
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    // Floor the lot size to ensure we don't exceed risk
    lotSize = MathFloor(lotSize / stepLot) * stepLot;

    lotSize = MathMax(minLot, lotSize);
    lotSize = MathMin(maxLot, lotSize);

    // Calculate actual risk with floored lot size
    double actualRisk = lotSize * pips * pipValue;
    if(verbose) {
        Print("Lot size: ", DoubleToString(lotSize, 2),
            " Actual risk: ", DoubleToString(actualRisk, 2),
            " Target risk: ", DoubleToString(riskDollars, 2));
    }

    return lotSize;
}

double CalculateTpPrice(double entryPrice, double slPrice, double minRRR, string symbol = NULL) {
    if(symbol == NULL) symbol = _Symbol;
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double risk = MathAbs(entryPrice - slPrice);
    double reward = risk * minRRR;
    double tpPrice;

    if (entryPrice > slPrice) {
        // Buy order
        tpPrice = entryPrice + reward;
    } else {
        // Sell order
        tpPrice = entryPrice - reward;
    }
    return NormalizeDouble(tpPrice, digits);
}

bool HasActivePositionsOrOrders(string symbol = NULL) {
    if(symbol == NULL) symbol = _Symbol;
    bool hasActive = false;

    // Check open positions
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(ticket != 0 && PositionGetString(POSITION_SYMBOL) == symbol) {
            hasActive = true;
            break;
        }
    }

    // check pending orders
    for(int i = 0; i < OrdersTotal(); i++) {
        ulong orderTicket = OrderGetTicket(i);
        if(orderTicket != 0) {
            if(OrderSelect(orderTicket) && OrderGetString(ORDER_SYMBOL) == symbol) {
                hasActive = true;
            }
        }
    }

    return hasActive;
}

void MoveSymbolStopLossToBreakeven(double beRRR = 1.0, string symbol = NULL) {
    if(symbol == NULL) symbol = _Symbol;
    bool shouldMoveToBreakeven = false;

    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(ticket != 0 && PositionGetString(POSITION_SYMBOL) == symbol) {
            ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double slPrice = PositionGetDouble(POSITION_SL);
            double tpPrice = PositionGetDouble(POSITION_TP);
            double newSlPrice = entryPrice;

             // Skip if SL already at or past BE
            if((positionType == POSITION_TYPE_BUY && slPrice >= entryPrice) || (positionType == POSITION_TYPE_SELL && slPrice <= entryPrice)) {
                continue;
            }

            double mvmtNeeded = MathAbs(entryPrice - slPrice) * beRRR;

            if(positionType == POSITION_TYPE_BUY) {
                double currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
                shouldMoveToBreakeven = (currentPrice >= entryPrice + mvmtNeeded);
            } else if(positionType == POSITION_TYPE_SELL) {
                double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
                shouldMoveToBreakeven = (currentPrice <= entryPrice - mvmtNeeded);
            }

            if(shouldMoveToBreakeven) {
                if(!trade.PositionModify(ticket, newSlPrice, tpPrice)) {
                    Print("Failed to move SL to BE. Error: ", GetLastError());
                } else {
                    Print("SL moved to BE successfully.");
                }
            }
        }
    }
}

// take partial profit on running trades based on given percent e.g 0.5 for 50%
bool TakePartialProfit(double partialRRR = 1.0, double percent = 0.5, string symbol = NULL) {
    if(symbol == NULL) symbol = _Symbol;
    bool partialTaken = false;
    bool shouldTakePartial = false;

    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(ticket != 0 && PositionGetString(POSITION_SYMBOL) == symbol) {
            ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double slPrice = PositionGetDouble(POSITION_SL);
            double lotSize = PositionGetDouble(POSITION_VOLUME);
            double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
            double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

             // Skip if SL already at or past BE
            if((positionType == POSITION_TYPE_BUY && slPrice >= entryPrice) || (positionType == POSITION_TYPE_SELL && slPrice <= entryPrice)) {
                continue;
            }

            double partialLotSize = lotSize * percent;
            partialLotSize = NormalizeDouble(MathFloor(partialLotSize / stepLot) * stepLot, 2);

            if(partialLotSize < minLot) {
                partialLotSize = minLot;
            }

            double mvmtNeeded = MathAbs(entryPrice - slPrice) * partialRRR;

            if(positionType == POSITION_TYPE_BUY) {
                double currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
                shouldTakePartial = (currentPrice >= entryPrice + mvmtNeeded);
            } else if(positionType == POSITION_TYPE_SELL) {
                double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
                shouldTakePartial = (currentPrice <= entryPrice - mvmtNeeded);
            }

            if(shouldTakePartial) {
                if(!trade.PositionClosePartial(ticket, partialLotSize)) {
                    Print("Failed to take partial profit. Error: ", GetLastError());
                } else {
                    partialTaken = true;
                    Print("Partial profit taken successfully. Lot size: " + DoubleToString(partialLotSize) + " of total lot size: " + DoubleToString(NormalizeDouble(lotSize, 2)));
                }
            }
        }
    }
    return partialTaken;
}

bool isTradingAllowedBySystem() {
    // Check if automated trading is allowed in the terminal
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        Print("Automated trading is not allowed in the terminal.");
        return false;
    }

    // Check if trading is allowed on this account
    if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) {
        Print("Trading not allowed: Broker has disabled trading for this account.");
        return false;
    }

    return true;
}
