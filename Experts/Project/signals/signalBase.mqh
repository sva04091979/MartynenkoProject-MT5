#include  "../newBarCtrl.mqh"
#include "../lib/tools/common.mqh"

class TSignalBase{
public:
   struct TInfo{
      string ToString() const;
   
      bool signalOpenBuy;
      bool signalOpenSell;
      bool signalCloseBuy;
      bool signalCloseSell;
   };
public:
   bool CheckSignal(const TNewBarCtrl::TCtrlInfo& _newBar, TInfo& _signal);
   ENUM_INIT_RETCODE Start(int _lastDeinitReason);

private:
   virtual bool ComputeSignal(const TNewBarCtrl::TCtrlInfo& _newBar, TInfo& _info) = 0;
   virtual ENUM_INIT_RETCODE ChartChange() = 0;
   virtual ENUM_INIT_RETCODE ParametersChange() = 0;
};

bool TSignalBase::CheckSignal(const TNewBarCtrl::TCtrlInfo& _newBar, TInfo& _signal){
   bool ret = ComputeSignal(_newBar, _signal);
   if (ret){
      PLATFORM_INFO(StringFormat(
         "[TSignal::CheckSignal] Signal: %s.",
         _signal.ToString() 
      ));
   }
   return ret;
}

ENUM_INIT_RETCODE TSignalBase::Start(int _lastDeinitReason){
   switch(_lastDeinitReason){
      case REASON_PROGRAM : ParametersChange();
      case REASON_CHARTCHANGE: return ChartChange();
      case REASON_PARAMETERS: return ParametersChange();
   }
   return INIT_SUCCEEDED;
}

string TSignalBase::TInfo::ToString() const{
   return StringFormat("(Buy/Sell) Open: %s/%s; Close: %s/%s",
      Lib::BoolToString(signalOpenBuy),
      Lib::BoolToString(signalOpenSell),
      Lib::BoolToString(signalCloseBuy),
      Lib::BoolToString(signalCloseSell)
   );
}