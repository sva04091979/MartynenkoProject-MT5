#include "lib/tools/common.mqh"
#include "input.mqh"

class TRisk{
public:
   static double ComputeVolume();
};

double TRisk::ComputeVolume(){
   static string symbol = "";
   static int lotDigits = 0;
   if(_Symbol != symbol){
      symbol = _Symbol;
      double volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      lotDigits= MathMax(-(int)MathFloor(MathLog10(volumeStep)),0);
   }
   double ballance = AccountInfoDouble(ACCOUNT_BALANCE)/100.0;
   double volume = NormalizeDouble(in_volume * ballance, lotDigits);
   volume = MathMax(volume, SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN));
   volume = MathMin(volume, SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX));
   return volume;
}