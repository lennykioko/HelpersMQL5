//+------------------------------------------------------------------+
//|                                                 TextDisplay.mqh |
//|                                  Copyright 2025 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property strict

// Global counter to track number of text labels
static int textCounter = 0;

//+------------------------------------------------------------------+
//| Function to add text to the screen                               |
//+------------------------------------------------------------------+
void addTextOnScreen(string message, color textColor=clrWhite)
{
   string objName = "text_" + IntegerToString(textCounter);
   int yOffset = 10 + textCounter * 30; // 10 base + 30 pixels per line

   // Create and configure the label object
   if(!ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0))
   {
      Print("Failed to create object: ", objName, " Error: ", GetLastError());
      return;
   }

   ObjectSetString(0, objName, OBJPROP_TEXT, message);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, yOffset);

   textCounter++;
}

//+------------------------------------------------------------------+
//| Clear all text objects with the given prefix                     |
//+------------------------------------------------------------------+
void clearTextDisplay(string prefix="text_")
{
   ObjectsDeleteAll(0, prefix);
   textCounter = 0;
}