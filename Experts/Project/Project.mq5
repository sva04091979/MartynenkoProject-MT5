#define __LIB_LOG__

#include "signals/2/signal2.mqh"
#include "riskCtrl.mqh"
#include "trade.mqh"
#include "version.mqh"

#include "lib/tools/start.mqh"

TNewBarCtrl g_newBar;
TSignal2 g_signal;
TTrade g_trade;

int OnInit()
{
#ifdef COMMIT
PrintFormat("Commit: %s", COMMIT);
#endif
   return Lib::TStart::OnInit(Start);
}

void OnDeinit(const int reason){
   Lib::TStart::OnDeinit(reason, Stop);
}

void OnTick()
{
   g_trade.Control();
   TNewBarCtrl::TCtrlInfo newBar;
   if (g_newBar.CheckNewBars(newBar)){
      TSignalBase::TInfo signal = {};
      if (g_signal.CheckSignal(newBar, signal)){
         if (signal.signalCloseBuy){
            g_trade.CloseAll(Lib::eBuy);            
         }
         if (signal.signalCloseSell){
            g_trade.CloseAll(Lib::eSell);                     
         }
         if (signal.signalOpenBuy){
            g_trade.Open(Lib::eBuy);
         }
         if (signal.signalOpenSell){
            g_trade.Open(Lib::eSell);         
         }
      }
   }
}

void OnTradeTransaction(const MqlTradeTransaction& _trans,
                        const MqlTradeRequest& _request,
                        const MqlTradeResult& _result)
{
   g_trade.OnTradeTransaction(_trans, _request, _result);
}

ENUM_INIT_RETCODE Start(int _lastDeinitReason){
   ENUM_INIT_RETCODE newBar = g_newBar.Start(_lastDeinitReason);
   ENUM_INIT_RETCODE signal = g_signal.Start(_lastDeinitReason);
   if (newBar != INIT_SUCCEEDED){
      return newBar;
   }
   if (signal != INIT_SUCCEEDED){
      return signal;
   }
   return INIT_SUCCEEDED;
}

void Stop(int _reason){}