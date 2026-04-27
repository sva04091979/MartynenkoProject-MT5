#include "waveCtrl.mqh"

#include "../signalBase.mqh"
#include "../../input.mqh"

class TSignal1: public TSignalBase{
private:
   bool ComputeSignal(const TNewBarCtrl::TCtrlInfo& _newBar, TInfo& _info) override;
   ENUM_INIT_RETCODE ChartChange() override;
   ENUM_INIT_RETCODE ParametersChange() override;

private:
   TWavesCtrl fastWaveCtrl_;
};

bool TSignal1::ComputeSignal(const TNewBarCtrl::TCtrlInfo& _newBar, TInfo& _info){
   if (!_newBar.fastMacd.isNewBar){
      return false;
   }
   TWavesCtrl::TInfo* info = fastWaveCtrl_.Compute(_newBar.fastMacd.time);
   if(!info){
      return false;   
   }
   if (info.buy == TWaveDirect::eC){
      PLATFORM_INFO("[TSignal1::ComputeSignal] Signal BUY");
      _info.signalOpenBuy = true;
      _info.signalCloseSell = true;
      return true;
   }
   if (info.sell == TWaveDirect::eC){
      PLATFORM_INFO("[TSignal1::ComputeSignal] Signal SELL");
      _info.signalOpenSell = true;
      _info.signalCloseBuy = true;
      return true;
   }
   return false;
}

ENUM_INIT_RETCODE TSignal1::ChartChange(){
   return fastWaveCtrl_.ChartChange();
}

ENUM_INIT_RETCODE TSignal1::ParametersChange(){
   TWavesCtrl::TParams tmp;
   tmp.macd.fastEma = in_fastMacdFastEma;
   tmp.macd.slowEma = in_fastMacdSlowEma;
   tmp.macd.macdSma = in_fastMacdSma;
   tmp.macd.applied = in_fastMacdApplied;
   tmp.filter = in_fastMacdFilter;
   return fastWaveCtrl_.ParametersChange(in_fastMacdTf, tmp);
}