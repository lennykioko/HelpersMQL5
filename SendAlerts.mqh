//+------------------------------------------------------------------+
//|                                             SendAlerts.mqh       |
//|                                             Copyright 2025       |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      "https://www.mql5.com"
#property strict

//+------------------------------------------------------------------+
//| Send Telegram Notification                                       |
//+------------------------------------------------------------------+
void SendTelegramAlert(string botToken, string chatId, string message, bool EnableTelegramAlerts = true) {
   if(!EnableTelegramAlerts) {
      Print("Telegram alerts are disabled.");
      return;
   }

   if(botToken == "" || chatId == "") {
      Print("Chat ID or Bot Token is not set. Cannot send Telegram notification.");
      return;
   }

   string headers;
   char post[], result[];
   string url = "https://api.telegram.org/bot" + botToken + "/sendMessage?chat_id=" + chatId + "&text=" + message + "&parse_mode=html";

   ResetLastError();
   int send = WebRequest("POST", url, NULL, NULL, 5000, post, 0, result, headers);
}