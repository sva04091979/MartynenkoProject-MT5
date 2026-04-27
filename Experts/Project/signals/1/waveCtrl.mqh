#include "waveDirect.mqh"
#include "../../log.mqh"

#include "../../lib/indicator/macd.mqh"

class TWavesCtrl{
public:
   class TInfo{
   public:
      TWaveDirect::EWave buy;
      TWaveDirect::EWave sell;
   };
   
   struct TParams{
      Lib::TMacd::TParams macd;
      uint filter;
   };
public:
   TWavesCtrl();
   TInfo* Compute(datetime _time);

   ENUM_INIT_RETCODE ChartChange();
   ENUM_INIT_RETCODE ParametersChange(ENUM_TIMEFRAMES _tf, const TParams& _params);
private:
   TInfo* Init(datetime _time);
   TInfo* ComputeImpl(datetime _time);   
   TInfo* ComputeImpl(datetime _time, uint _size);   
   void Reset();
   void SetFilter(uint _filter);
   
   static bool ComputeNewSignal(TWaveDirect::EWave& _state, TWaveDirect::EWave _selfSwitch, TWaveDirect::EWave _otherSwitch);
private:
   Lib::TMacd macd_;
   Lib::TMacd::TInfoArr infoMacd_;
   TWaveDirect buy_;
   TWaveDirect sell_;
   TInfo infoWave_;
   datetime lastTime_;
};

TWavesCtrl::TWavesCtrl(void):
   buy_(Lib::eBuy),
   sell_(Lib::eSell),
   lastTime_(0){
   infoMacd_.AsSeries(false);
}

void TWavesCtrl::Reset(){
   lastTime_ = 0;
   buy_.Reset();
   sell_.Reset();
}

void TWavesCtrl::SetFilter(uint _filter){
   const Lib::TTimeframe* tf = macd_.Timeframe();
   double filter = tf.Point() * _filter;
   buy_.SetFilter(filter);
   sell_.SetFilter(filter);
}

TWavesCtrl::TInfo* TWavesCtrl::Compute(datetime _time){
   if(!lastTime_){
      return Init(_time);
   }
   return ComputeImpl(_time);
}

TWavesCtrl::TInfo* TWavesCtrl::ComputeImpl(datetime _time){
   const Lib::TTimeframe* tf = macd_.Timeframe();
   int size = tf.BarShift(lastTime_);
   if (size < 1){
      PLATFORM_ERROR("[TWavesCtrl::ComputeImpl] Something gone wrong.");
      return NULL;
   }
   return ComputeImpl(_time, size);
}

TWavesCtrl::TInfo* TWavesCtrl::Init(datetime _time){
   const Lib::TTimeframe* tf = macd_.Timeframe();
   int size = tf.Bars();
   if (size < 0){
      PLATFORM_ERROR("[TWavesCtrl::Init] Something gone wrong.");
      return NULL;
   }
   return ComputeImpl(_time, size - 1);
}

TWavesCtrl::TInfo* TWavesCtrl::ComputeImpl(datetime _time, uint _size){
   if (!_size){
      return NULL;
   }
   if (!macd_.GetInfo(infoMacd_, _size, 1)){
      return NULL;
   }
   if (infoMacd_.mainSize != _size || infoMacd_.signalSize != _size){
      PLATFORM_ERROR("[TWavesCtrl::ComputeImpl] Not all indicators buffers has loaded.");
      return NULL;
   }
   const Lib::TTimeframe* tf = macd_.Timeframe();
   lastTime_ = _time;
   bool isBuy = false;
   bool isSell = false;
   for(uint i=0; i < _size; ++i){
      datetime time = tf.Time(_size - i);
      double macd = infoMacd_.main[i];
      if (macd == EMPTY_VALUE){
         continue;
      }
      TWaveDirect::EWave buy = buy_.Check(time, macd);
      TWaveDirect::EWave sell = sell_.Check(time, macd);
      isBuy = ComputeNewSignal(infoWave_.buy, buy, sell);
      isSell = ComputeNewSignal(infoWave_.sell, sell, buy);
   }
   if (isBuy || isSell) {
      return &infoWave_;
   }
   return NULL;
}

bool TWavesCtrl::ComputeNewSignal(TWaveDirect::EWave& _state, TWaveDirect::EWave _selfSwitch, TWaveDirect::EWave _otherSwitch){
   if (_otherSwitch == TWaveDirect::eA){
      _state = TWaveDirect::eNo;
   }
   _state = _selfSwitch;
   return _state == TWaveDirect::eC;
}

ENUM_INIT_RETCODE TWavesCtrl::ChartChange(){
   bool res = macd_.Init(_Symbol, _Period);
   if (macd_.HasReinited()){
      Reset();
   }
   if (res){
      return INIT_SUCCEEDED;
   }
   return INIT_FAILED;
}

ENUM_INIT_RETCODE TWavesCtrl::ParametersChange(ENUM_TIMEFRAMES _tf, const TParams& _params){
   bool res = macd_.Reset(_tf, _params.macd, true);
   if (macd_.HasReinited()){
      Reset();
   }
   SetFilter(_params.filter);
   if (res){
      return INIT_SUCCEEDED;
   }
   return INIT_FAILED;
}
