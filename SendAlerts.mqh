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
void SendTelegramAlert(string TelegramBotToken, string TelegramChatId, string TelegramMessage, bool TelegramEnableTelegramAlerts = true) {
   if(!TelegramEnableTelegramAlerts) {
      Print("Telegram alerts are disabled.");
      return;
   }

   if(TelegramBotToken == "" || TelegramChatId == "") {
      Print("Chat ID or Bot Token is not set. Cannot send Telegram notification.");
      return;
   }

   string headers;
   char post[], result[];
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage?chat_id=" + TelegramChatId + "&text=" + TelegramMessage + "&parse_mode=html";

   ResetLastError();
   int send = WebRequest("POST", url, NULL, NULL, 5000, post, 0, result, headers);
}
