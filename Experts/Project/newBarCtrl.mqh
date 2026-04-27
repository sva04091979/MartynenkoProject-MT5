#include "lib/chart/newbar.mqh"
#include "input.mqh"
#include "log.mqh"

class TNewBarCtrl{
public:
   struct TInfo{
      bool isNewBar;
      datetime time;
      datetime lastTime;
   };
   struct TCtrlInfo{
      TInfo fastMacd;
      TInfo slowMacd;
   };
public:
   TNewBarCtrl();
   bool CheckNewBars(TCtrlInfo& _info);
   ENUM_INIT_RETCODE Start(int _lastDeinitReason);
private:
   ENUM_INIT_RETCODE ChartChange();
   ENUM_INIT_RETCODE ParametersChange();
   
private:
   Lib::TNewBar fastMacd_;
   Lib::TNewBar slowMacd_;
};

bool TNewBarCtrl::CheckNewBars(TCtrlInfo &_info){
   _info.fastMacd.time = fastMacd_.IsNewBar(_info.fastMacd.lastTime);
   _info.fastMacd.isNewBar = _info.fastMacd.time != 0;
   _info.slowMacd.time = slowMacd_.IsNewBar(_info.slowMacd.lastTime);
   _info.slowMacd.isNewBar = _info.slowMacd.time != 0;
   
   return _info.fastMacd.isNewBar || _info.slowMacd.isNewBar;
}

TNewBarCtrl::TNewBarCtrl(void):
   fastMacd_(in_fastMacdTf),
   slowMacd_(in_slowMacdTf)
   {}

ENUM_INIT_RETCODE TNewBarCtrl::Start(int _lastDeinitReason){
   switch(_lastDeinitReason){
      case REASON_PROGRAM : ParametersChange();
      case REASON_CHARTCHANGE: return ChartChange();
      case REASON_PARAMETERS: return ParametersChange();
   }
   return INIT_SUCCEEDED;
}

ENUM_INIT_RETCODE TNewBarCtrl::ChartChange(){
   if (fastMacd_.Set(_Symbol, _Period)){
      fastMacd_.IsNewBar();
   }
   if (slowMacd_.Set(_Symbol, _Period)){
      slowMacd_.IsNewBar();
   }
   return INIT_SUCCEEDED;
}

ENUM_INIT_RETCODE TNewBarCtrl::ParametersChange(){
   if (in_fastMacdTf >= in_slowMacdTf){
      PLATFORM_ERROR(StringFormat(
         "[TNewBarCtrl::ParametersChange()] in_fastMacdTf(%s) >= in_slowMacdTf(%s)",
         EnumToString(in_fastMacdTf),
         EnumToString(in_slowMacdTf)
      ));
   }
   if (fastMacd_.Reset(in_fastMacdTf)){
      fastMacd_.IsNewBar();
   }
   if (slowMacd_.Reset(in_slowMacdTf)){
      slowMacd_.IsNewBar();
   }
   return INIT_SUCCEEDED;   
}