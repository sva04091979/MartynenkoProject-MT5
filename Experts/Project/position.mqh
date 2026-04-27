#include "lib/tools/common.mqh"

#include "log.mqh"
#include <Generic\SortedMap.mqh>
#include <Trade\Trade.mqh>

class TPosition{
public:
   enum EState{
      eIdle,
      ePendingOpen,
      ePendedOpen,
      eOpening,
      eOpened,
      ePendingClose,
      ePendedClose,
      eClosing,
      eFinished,
      eError
   };
   
public:
   TPosition(Lib::ETradeDirect _direct);
   EState Control();
   bool OnTradeTransaction(const MqlTradeTransaction& _trans,
                           const MqlTradeRequest& _request,
                           const MqlTradeResult& _result);
   EState Open(double _volume);
   EState Open(double _volume, uint _sl);
   EState Pend(double volume, double price);
   EState Close();
   void SetSl(uint _sl);
   Lib::ETradeDirect Direct() const { return direct_; }
private:
   EState ControlImpl();
   EState PendingOpenControl();
   EState PendedOpenControl();
   EState OpeningControl();
   EState OpenedControl();
   EState PendingCloseControl();
   EState PendedCloseControl();
   EState ClosingControl();

   EState PendedOpenControlImpl();
   EState DoHistoryOrderOpen();
   EState DoHistoryOrderClose();
   
   EState OpenImpl(double _volume);
   EState CloseImpl();
   EState ClosePendedImpl();
   EState CloseOpenedImpl();
   EState ClosePendedProcess();
   EState CloseOpenedProcess();

   EState PosSlCtrl();
 
   static int CheckHistoryOrderResult(ulong _order);
   ulong GetOpenDeal();
   ulong GetCloseDeal();
   
private:
   CTrade trade_;
   CSortedMap<long, ulong> closeOrders_;
   CSortedMap<long, ulong> closeDeals_;
   ulong id_;
   ulong openOrder_;
   ulong openDeal_;
   ulong position_;
   ulong closeProcessOrder_;
   double volume_;
   double closingVolune_;
   double sl_;
   uint slPips_;
   const Lib::ETradeDirect direct_;
   EState state_;
   bool needClose_;
   bool needCheckSl_;
   bool needComputeSl_;
};

TPosition::TPosition(Lib::ETradeDirect _direct):
   id_(0),
   position_(0),
   openOrder_(0),
   openDeal_(0),
   closeProcessOrder_(0),
   volume_(0.0),
   closingVolune_(0.0),
   sl_(0.0),
   slPips_(0.0),
   direct_(_direct),
   state_(eIdle),
   needClose_(false),
   needCheckSl_(false),
   needComputeSl_(false)
   {}

TPosition::EState TPosition::Control(){
   state_ = ControlImpl();
   return state_;
}

TPosition::EState TPosition::ControlImpl(){
   switch(state_){
      case eIdle: return eIdle;
      case ePendingOpen: return PendingOpenControl();
      case ePendedOpen: return PendedOpenControl();
      case eOpening: return OpeningControl();
      case eOpened: return OpenedControl();
      case ePendingClose: return PendingCloseControl();
      case ePendedClose: return PendedCloseControl();
      case eClosing: return ClosingControl();
      case eFinished: return eFinished;
      case eError: return eError;
   }
   PLATFORM_ERROR("[TPosition::ControlImpl] Something gone wrong!");
   return eError;
}

TPosition::EState TPosition::Open(double _volume){
   state_ = OpenImpl(_volume);
   return state_;
}

TPosition::EState TPosition::Open(double _volume, uint _sl){
   SetSl(_sl);
   state_ = OpenImpl(_volume);
   return state_;
}

void TPosition::SetSl(uint _sl){
   slPips_ = _sl;
   needCheckSl_ = true;
   needComputeSl_ = true;
}

TPosition::EState TPosition::OpenImpl(double _volume){
   if (state_ != eIdle){
      return eError;
   }
   bool res = direct_ > 0? trade_.Buy(_volume): trade_.Sell(_volume);
   if (!res){
      return eError;
   }
   ulong order = trade_.ResultOrder();
   ulong deal = trade_.ResultDeal();
   if (order){
      openOrder_ = order;
      if (deal){
         openDeal_ = deal;
         id_ = openOrder_;
         position_ = openOrder_;
         return OpenedControl();
      }
      return ePendedOpen;
   }
   return eError;
}

TPosition::EState TPosition::Close(){
   closingVolune_ = volume_;
   state_ = CloseImpl();
   return state_;
}

TPosition::EState TPosition::PendingOpenControl(void){
   if (OrderSelect(openOrder_)){
      return PendedOpenControlImpl();
   }
   if (!HistoryOrderSelect(openOrder_)){
      return ePendingOpen;
   }
   return DoHistoryOrderOpen();
}

TPosition::EState TPosition::PendedOpenControl(void){
   if (OrderSelect(openOrder_)){
      return PendedOpenControlImpl();
   }
   if (!HistoryOrderSelect(openOrder_)){
      return eError;
   }
   return DoHistoryOrderOpen();
}

TPosition::EState TPosition::PendedOpenControlImpl(void){
   if(needClose_){
      ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      switch (type){
         case ORDER_TYPE_BUY_LIMIT:
         case ORDER_TYPE_BUY_STOP:
         case ORDER_TYPE_BUY_STOP_LIMIT:
         case ORDER_TYPE_SELL_LIMIT:
         case ORDER_TYPE_SELL_STOP:
         case ORDER_TYPE_SELL_STOP_LIMIT: return ClosePendedProcess();
      }
   }
   return ePendedOpen;
}

TPosition::EState TPosition::DoHistoryOrderOpen(){
   int res = CheckHistoryOrderResult(openOrder_);
   if (!res){
      return eError;
   }
   if (res < 0){
      return eFinished;
   }
   id_ = openOrder_;
   return OpeningControl();
}

TPosition::EState TPosition::OpeningControl(void){
   openDeal_ = GetOpenDeal();
   if (!openDeal_){
      return eOpening;
   }
   position_ = id_;
   return OpenedControl();
}

TPosition::EState TPosition::OpenedControl(){
   if (!PositionSelectByTicket(position_)){
      position_ = 0;
      volume_ = 0.0;
      return ClosingControl();      
   }
   double volume = PositionGetDouble(POSITION_VOLUME);
   if (!volume_){
      volume_ = volume;
   } else if (volume < volume_){
      volume_ = volume;
      return ClosingControl();
   }
   if (needClose_){
      return CloseOpenedProcess();
   }
   return PosSlCtrl();   
}

TPosition::EState TPosition::PosSlCtrl(void){
   if (!needCheckSl_){
      return eOpened;
   }
   int digits = (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS);
   if (needComputeSl_){
      double sl = PositionGetDouble(POSITION_PRICE_OPEN) - direct_ * (slPips_ * SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_POINT));
      needComputeSl_ = false;
      if (sl == sl_){
         needCheckSl_ = Lib::Compare(sl_, PositionGetDouble(POSITION_SL), digits) != Lib::eEqual;
      }
      sl_ = sl;
   }
   if (needCheckSl_){
      needCheckSl_ = !trade_.PositionModify(position_, sl_, PositionGetDouble(POSITION_TP));
   }
   if (needCheckSl_){
      double price = direct_ > 0? SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_BID): SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_ASK);
      Lib::ECompare res = direct_ > 0? Lib::Compare(price, sl_, digits): Lib::Compare(sl_, price, digits);
      if (res != Lib::eGreater){
         return Close();
      }
   }
   return eOpened;
}

TPosition::EState TPosition::PendingCloseControl(void){
   if (OrderSelect(closeProcessOrder_)){
      return ePendedClose;
   }
   if (!HistoryOrderSelect(closeProcessOrder_)){
      return ePendingClose;
   }
   return DoHistoryOrderClose();
}

TPosition::EState TPosition::PendedCloseControl(void){
   if (OrderSelect(closeProcessOrder_)){
      return ePendedClose;
   }
   if (!HistoryOrderSelect(closeProcessOrder_)){
      return eError;
   }
   return DoHistoryOrderClose();
}

TPosition::EState TPosition::DoHistoryOrderClose(){
   int res = CheckHistoryOrderResult(closeProcessOrder_);
   if (!res){
      return eError;
   }
   if (res < 0){
      state_ = eOpened;
      return OpenedControl();
   }
   long time = HistoryOrderGetInteger(closeProcessOrder_, ORDER_TIME_DONE_MSC);
   closeOrders_.Add(time, closeProcessOrder_);
   return ClosingControl();
}

TPosition::EState TPosition::ClosingControl(){
   ulong deal = GetCloseDeal();
   if (!deal){
      return eClosing;
   }
   long dealTime = HistoryDealGetInteger(deal, DEAL_TIME_MSC); 
   closeDeals_.Add(dealTime, deal);
   if (!closeProcessOrder_){
      closeProcessOrder_ = HistoryDealGetInteger(deal, DEAL_ORDER);
      long time = HistoryOrderGetInteger(closeProcessOrder_, ORDER_TIME_DONE_MSC);
      closeOrders_.Add(time, closeProcessOrder_);
   }
   closeProcessOrder_ = 0;
   if (!position_){
      return eFinished;
   }
   double volume = 0.0;
   if (PositionSelectByTicket(position_)){
      volume = PositionGetDouble(POSITION_VOLUME);
   }
   volume_ = volume;
   needClose_ = false;
   closingVolune_ = 0.0;
   return !volume? eFinished: eOpened;
}

TPosition::EState TPosition::CloseImpl(void){
   needClose_ = true;
   switch(Control()){
      case ePendedOpen: return ClosePendedImpl();
      case eOpened: return CloseOpenedImpl();
      default: return state_;
   }
}

TPosition::EState TPosition::ClosePendedImpl(void){
   if (OrderSelect(openOrder_)){
      return ClosePendedProcess();
   }
   return DoHistoryOrderOpen();
}

TPosition::EState TPosition::ClosePendedProcess(void){
   switch((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)){
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_SELL:
      case ORDER_TYPE_CLOSE_BY: return ePendedOpen;
   }
   if (!trade_.OrderDelete(openOrder_)){
      PLATFORM_ERROR("[TPosition::ClosePendedProcess] OrderDelete returned 'false");
      return ePendedOpen;
   }
   switch(trade_.ResultRetcode()){
      case TRADE_RETCODE_DONE: return eFinished;
   }
   return ePendedOpen;
}

TPosition::EState TPosition::CloseOpenedImpl(void){
   if (PositionSelectByTicket(position_)){
      return CloseOpenedProcess();
   }
   position_ = 0;
   volume_ = 0.0;
   return ClosingControl();      
}

TPosition::EState TPosition::CloseOpenedProcess(void){
   bool res = closingVolune_ == volume_? trade_.PositionClose(position_): 
                                         trade_.PositionClosePartial(position_, closingVolune_);
   if(!res){
      PLATFORM_ERROR("[TPosition::CloseOpenedProcess] PositionClose returned 'false");
      return eOpened;
   }
   ulong order = trade_.ResultOrder();
   ulong deal = trade_.ResultDeal();
   if(order){
      long orderTime = HistoryOrderGetInteger(order, ORDER_TIME_DONE_MSC);
      closeOrders_.Add(orderTime, order);
      if (deal){
         long dealTime = HistoryDealGetInteger(closeProcessOrder_, DEAL_TIME_MSC);
         closeDeals_.Add(dealTime, deal);
         position_ = 0;
         return eFinished;      
      }
      return ePendedClose;
   }
   return ePendingOpen;
}

int TPosition::CheckHistoryOrderResult(ulong _order){
   ENUM_ORDER_STATE state = (ENUM_ORDER_STATE)HistoryOrderGetInteger(_order, ORDER_STATE);
   switch(state){
      case ORDER_STATE_FILLED:
      case ORDER_STATE_PARTIAL: return 1;
      case ORDER_STATE_CANCELED:
      case ORDER_STATE_REJECTED:
      case ORDER_STATE_EXPIRED: return -1;
      default:
         PLATFORM_ERROR(StringFormat("[TPosition::CheckHistoryOrderResult] Unexpected state %s", EnumToString(state)));
         return 0;
   }
}

ulong TPosition::GetOpenDeal(void){
   if (!HistorySelectByPosition(id_)){
      return 0;
   }
   int size = HistoryDealsTotal();
   for (int i = 0; i < size; ++i){
      ulong deal = HistoryDealGetTicket(i);
      if(!deal){
         continue;
      }
      if (HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_IN){
         return deal;
      }
   }
   return 0;
}

ulong TPosition::GetCloseDeal(void){
   if (!HistorySelectByPosition(id_)){
      return 0;
   }
   int size = HistoryDealsTotal();
   for (int i = 0; i < size; ++i){
      ulong deal = HistoryDealGetTicket(i);
      if(!deal){
         continue;
      }
      if (HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_OUT){
         long time = HistoryDealGetInteger(deal, DEAL_TIME_MSC);
         if (!closeDeals_.ContainsKey(time)){
            return deal;
         }
      }
   }
   return 0;   
}