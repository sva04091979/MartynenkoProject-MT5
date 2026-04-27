#include "../../lib/tools/common.mqh"
#include "../../log.mqh"
class TWaveDirect{
public:
   enum EWave{
      eNo,
      ePreA,
      eA,
      eC
   };
public:
   TWaveDirect(Lib::ETradeDirect _direct);
   EWave Check(datetime _time, double _main);
   void Reset();
   void SetFilter(double _filter);

private:
   EWave ControlNo(double _main);
   EWave ControlPreA(double _main);
   EWave ControlA(double _main);
   EWave ControlC(double _main);
   
private:
   const Lib::ETradeDirect direct_;
   EWave currentWave_;
   double filter_;
   double zero_;
   double lastMax_;
   double currentMax_;
};

TWaveDirect::TWaveDirect(Lib::ETradeDirect _direct):
   direct_(_direct),
   filter_(0.0),
   zero_(0.0){
   Reset();
}

void TWaveDirect::Reset(void){
   currentWave_ = eNo;
   lastMax_ = filter_;
   currentMax_ = filter_;
}

void TWaveDirect::SetFilter(double _filter){
   filter_ = _filter;
   zero_ = -_filter;
   switch(currentWave_){
      case eNo:
      case eC:
         break;
      case eA:
         if (lastMax_ <= filter_){
            currentWave_ = eNo;
         }
         break;
   }
   lastMax_ = MathMax(filter_, lastMax_);
   currentMax_ = MathMax(filter_, currentMax_);
}

TWaveDirect::EWave TWaveDirect::Check(datetime _time, double _main){
      PLATFORM_INFO(StringFormat(
         "[TWaveDirect::Check] %s\n\tlast max = %f\n\tcurrent max = %f\nmain: %f", EnumToString(direct_), lastMax_, currentMax_, _main
      ));
   double main = _main * direct_;
   switch(currentWave_){
      case eNo: return ControlNo(main);
      case ePreA: return ControlPreA(main);
      case eA: return ControlA(main);
      case eC: return ControlC(main);
   }
   return eNo;
   }

TWaveDirect::EWave TWaveDirect::ControlNo(double _main){
   if (_main < filter_){
      currentWave_ = ePreA;
      return ControlPreA(_main);
   }
   currentMax_ = MathMax(currentMax_, _main);
   return eNo;
}

TWaveDirect::EWave TWaveDirect::ControlPreA(double _main){
   if (_main > filter_){
      lastMax_ = currentMax_;
      currentMax_ = _main;
      currentWave_ = eNo;
      return currentWave_;
   }
   if (_main < zero_){
      if(currentMax_ > lastMax_){
         PLATFORM_INFO(StringFormat(
            "[TWaveDirect::ControlPreA] A wave has founded on %s\nlast max = %f\ncurrent max = %f", EnumToString(direct_), lastMax_, currentMax_
         ));
         currentWave_ = eA;
      }
      lastMax_ = currentMax_;
      currentMax_ = filter_;
      return currentWave_;   
   }
   return eNo;
}

TWaveDirect::EWave TWaveDirect::ControlA(double _main){
   if (_main > filter_){
      currentMax_ = _main;
      currentWave_ = eC;
      PLATFORM_INFO(StringFormat(
         "[TWaveDirect::ControlA] C wave has founded on %s", EnumToString(direct_)
      ));
      return currentWave_;
   }
   return eNo;
}

TWaveDirect::EWave TWaveDirect::ControlC(double _main){
   return ControlNo(_main);
}
