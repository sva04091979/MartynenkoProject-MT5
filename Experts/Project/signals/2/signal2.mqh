#include "../signalBase.mqh"
#include "../../input.mqh"

#include "../../lib/indicator/macd.mqh"

class TSignal2: public TSignalBase{
public:
   TSignal2();
private:
   bool ComputeSignal(const TNewBarCtrl::TCtrlInfo& _newBar, TInfo& _info) override;
   ENUM_INIT_RETCODE ChartChange() override;
   ENUM_INIT_RETCODE ParametersChange() override;
private:
   bool ComputeSlow(TInfo& _signal);
   bool ComputeFast(TInfo& _signal);
   void Reset();
   
   static Lib::EDirect Direct(const Lib::TMacd::TInfoArr& _info, uint _i, double _filter, int _digits);
private:
   Lib::TMacd fastMacd_;
   Lib::TMacd slowMacd_;
   Lib::TMacd::TInfoArr fastInfo_;
   Lib::TMacd::TInfoArr slowInfo_;
   Lib::EDirect slowDirect_;
   Lib::EDirect fastDirect_;
   bool isStart_;
};

TSignal2::TSignal2():
   slowDirect_(Lib::eNoDirect),
   fastDirect_(Lib::eNoDirect),
   isStart_(true)
   {}

void TSignal2::Reset(void){
   fastDirect_ = Lib::eNoDirect;
}

bool TSignal2::ComputeSignal(const TNewBarCtrl::TCtrlInfo& _newBar, TInfo& _signal){
   bool ret = false;
   if (_newBar.slowMacd.isNewBar || isStart_){
      ret = ComputeSlow(_signal);
   }
   if (_newBar.fastMacd.isNewBar){
      ret = ComputeFast(_signal) || ret;
   }
   return ret;
}

bool TSignal2::ComputeSlow(TInfo& _signal){
   if (!slowMacd_.GetInfo(slowInfo_, 1, 1)){
      return false;
   }
   bool ret = false;
   int digits = slowMacd_.Digits();
   double filter = in_slowMacdFilter/ MathPow(10, digits);
   Lib::EDirect direct = Direct(slowInfo_, 0, filter, digits);
   if (direct && direct != slowDirect_){
      if(direct > 0){
         _signal.signalCloseSell = true;
         if (slowDirect_){
            _signal.signalOpenBuy = true;            
         }
      } else {
         _signal.signalCloseBuy = true;      
         if (slowDirect_){
            _signal.signalOpenSell = true;            
         }
      }
      ret = true;
      slowDirect_ = direct;
   }
   isStart_ = false;
   if (ret){
      PLATFORM_INFO(StringFormat(
         "[TSignal2::ComputeSlow] Signal has found. %s.",
         _signal.ToString()
      ));
   }
   return ret;
}

bool TSignal2::ComputeFast(TInfo& _signal){
   uint size = fastDirect_? 1: 2;
   if (!fastMacd_.GetInfo(fastInfo_, size, 1)){
      return false;
   }
   int digits = fastMacd_.Digits();
   double filter = in_fastMacdFilter / MathPow(10, digits);
   Lib::EDirect direct = Direct(fastInfo_, size - 1, filter, digits);
   if(!fastDirect_){
      while(true){
         fastDirect_ = Direct(fastInfo_, 0, filter, digits);
         if (fastDirect_){
            break;
         }
         if (!fastMacd_.GetInfo(fastInfo_, 1, ++size)){
            return false;
         }
      }
   }
   bool ret = false;
   if (direct && direct != fastDirect_){
      if(direct > 0){
         _signal.signalCloseSell = true;
         if (fastDirect_ && direct == slowDirect_){
            _signal.signalOpenBuy = true;
         }
      } else {
         _signal.signalCloseBuy = true;      
         if (fastDirect_ && direct == slowDirect_){
            _signal.signalOpenSell = true;
         }
      }
      ret = true;
      fastDirect_ = direct;
   }
   if (ret){
      PLATFORM_INFO(StringFormat(
         "[TSignal2::ComputeFast] Signal has found. %s.",
         _signal.ToString()
      ));
   }
   return ret;
}

Lib::EDirect TSignal2::Direct(const Lib::TMacd::TInfoArr& _info, uint _i, double _filter, int _digits){
   double main = _info.main[_i];
   double signal = _info.signal[_i];
   double delta = main - signal;
   if (Lib::Compare(MathAbs(delta), _filter, _digits) != Lib::eGreater){
      return Lib::eNoDirect;
   }
   return main > signal? Lib::eUp: Lib::eDown;
}

ENUM_INIT_RETCODE TSignal2::ChartChange(){
   bool res = slowMacd_.Init(_Symbol, _Period);
   res = fastMacd_.Init(_Symbol, _Period) && res;
   if (slowMacd_.HasReinited() || fastMacd_.HasReinited()){
      Reset();
   }
   if (res){
      return INIT_SUCCEEDED;
   }
   return INIT_FAILED;
}

ENUM_INIT_RETCODE TSignal2::ParametersChange(){
   Lib::TMacd::TParams tmp;
   tmp.fastEma = in_fastMacdFastEma;
   tmp.slowEma = in_fastMacdSlowEma;
   tmp.macdSma = in_fastMacdSma;
   tmp.applied = in_fastMacdApplied;
   bool res = fastMacd_.Reset(in_fastMacdTf, tmp, true);
   tmp.fastEma = in_slowMacdFastEma;
   tmp.slowEma = in_slowMacdSlowEma;
   tmp.macdSma = in_slowMacdSma;
   tmp.applied = in_slowMacdApplied;
   res = slowMacd_.Reset(in_slowMacdTf, tmp, true);
   if (slowMacd_.HasReinited() || fastMacd_.HasReinited()){
      Reset();
   }
   if (res){
      return INIT_SUCCEEDED;
   }
   return INIT_FAILED;
}