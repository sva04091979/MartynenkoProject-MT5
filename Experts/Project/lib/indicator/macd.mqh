#include "base.mqh"

namespace Lib{

class TMacd: public TIndicator{
public:
   struct TParams{
      uint  fastEma;
      uint  slowEma;
      uint  macdSma;
      ENUM_APPLIED_PRICE applied;
   };
   struct TInfo{
      double main;
      double signal;
   };
   struct TInfoArr{
      bool Resize(uint _size){
         bool ret = true;
         if (main.Size() != _size){
            ret = ArrayResize(main, _size) == _size;
         }
         if (signal.Size() != _size){
            ret = ArrayResize(signal, _size) == _size && ret;
         }
         return ret;
      }
      
      void AsSeries(bool _is){
         ArraySetAsSeries(main, _is);
         ArraySetAsSeries(signal, _is);
      }
      
      double main[];
      double signal[];
      int mainSize;
      int signalSize;
   };
public:
   using TIndicator::Reset;
   using TIndicator::Init;

   TMacd();
   
   bool Reset(const TParams& _params, bool _isShow);
   bool Reset(const string& _symbol, ENUM_TIMEFRAMES _tf, const TParams& _params, bool _isShow);
   bool Reset(const string& _symbol, const TParams& _params, bool _isShow);
   bool Reset(ENUM_TIMEFRAMES _t, const TParams& _params, bool _isShow);

   bool Init(const TParams& _params, bool _isShow);   
   bool Init(const string& _symbol, ENUM_TIMEFRAMES _tf, const TParams& _params, bool _isShow);
   bool Init(const string& _symbol, const TParams& _params, bool _isShow);
   bool Init(ENUM_TIMEFRAMES _t, const TParams& _params, bool _isShow);
   
   bool GetInfo(TInfo& _info, uint _i);
   bool GetInfo(TInfoArr& _info, uint _from);
   bool GetInfo(TInfoArr& _info, uint size, uint _from);

   bool GetMain(double& _info, uint _i);
   int GetMain(double& _info[], uint _from);
   int GetMain(double& _info[], uint size, uint _from);

   bool GetSignal(double& _info, uint _i);
   int GetSignal(double& _info[], uint _from);
   int GetSignal(double& _info[], uint size, uint _from);
   
private:
   bool ResetImpl(const TParams& _params);
   
private:
   bool CheckParams() const override;
   int GetHandle() const override;
   void SetDigits(const string& _symbol) override;
private:
   TParams params_;
};

TMacd::TMacd(void):
   TIndicator("MACD",2, true)
   {}

bool TMacd::Reset(const string& _symbol, ENUM_TIMEFRAMES _tf, const TParams& _params, bool _isShow){
   bool ret = ResetImpl(_params);
   if (!TIndicator::Reset(_symbol, _tf, _isShow) && ret){
      return InitImpl(_isShow);
   }
   return true;
}

bool TMacd::Reset(const TParams& _params, bool _isShow){
   return Reset(_Symbol, _Period, _params, _isShow);
}

bool TMacd::Reset(const string& _symbol, const TParams& _params, bool _isShow){
   return Reset(_symbol, _Period, _params, _isShow);
}

bool TMacd::Reset(ENUM_TIMEFRAMES _tf, const TParams& _params, bool _isShow){
   return Reset(_Symbol, _tf, _params, _isShow);
}

bool TMacd::Init(const string& _symbol, ENUM_TIMEFRAMES _tf, const TParams& _params, bool _isShow){
   bool ret = ResetImpl(_params);
   if (!TIndicator::Init(_symbol, _tf, _isShow) && ret){
      return InitImpl(_isShow);
   }
   return true;
}

bool TMacd::Init(const TParams& _params, bool _isShow){
   return Init(_Symbol, _Period, _params, _isShow);
}

bool TMacd::Init(const string& _symbol, const TParams& _params, bool _isShow){
   return Init(_symbol, _Period, _params, _isShow);
}

bool TMacd::Init(ENUM_TIMEFRAMES _tf, const TParams& _params, bool _isShow){
   return Init(_Symbol, _tf, _params, _isShow);
}

bool TMacd::GetInfo(TInfo& _info, uint _i){
   return GetMain(_info.main, _i) && GetSignal(_info.signal, _i);
}

bool TMacd::GetInfo(TInfoArr& _info, uint _from){
   _info.mainSize = GetMain(_info.main, _from);
   _info.signalSize = GetSignal(_info.signal, _from);
   return _info.mainSize == _info.main.Size() && _info.signalSize == _info.signal.Size();
}

bool TMacd::GetInfo(TInfoArr& _info, uint _size, uint _from){
   _info.mainSize = GetMain(_info.main, _size, _from);
   _info.signalSize = GetSignal(_info.signal, _size, _from);
   return _info.mainSize == _size && _info.signalSize == _size;
}

bool TMacd::GetMain(double& _info, uint _i){
   return GetBuffer(_info, 0, _i);
}

int TMacd::GetMain(double& _info[], uint _from){
   return GetBuffer(_info, 0, _from);
}

int TMacd::GetMain(double& _info[], uint size, uint _from){
   return GetBuffer(_info, size, 0, _from);
}

bool TMacd::GetSignal(double& _info, uint _i){
   return GetBuffer(_info, 1, _i);
}

int TMacd::GetSignal(double& _info[], uint _from){
   return GetBuffer(_info, 1, _from);
}

int TMacd::GetSignal(double& _info[], uint size, uint _from){
   return GetBuffer(_info, size, 1, _from);
}

bool TMacd::ResetImpl(const TParams &_params){
   bool ret = false;
   if(params_.applied != _params.applied){
      params_.applied = _params.applied;
      ret = true;
   }
   if(params_.fastEma != _params.fastEma){
      params_.fastEma = _params.fastEma;
      ret = true;
   }
   if(params_.slowEma != _params.slowEma){
      params_.slowEma = _params.slowEma;
      ret = true;
   }
   if(params_.macdSma != _params.macdSma){
      params_.macdSma = _params.macdSma;
      ret = true;
   }
   return ret;
}

bool TMacd::CheckParams() const{
   if (params_.fastEma >= params_.slowEma){
      INDICATOR_ERROR(StringFormat(
         "[TMacd::CheckParams] fastEMA(%u) >= slowEMA(%u)", 
         params_.fastEma, params_.slowEma));
      return false;
   }
   return true;
}

int TMacd::GetHandle() const{
   int ret = iMACD(tf_.Symbol(), tf_.Period(), params_.fastEma, params_.slowEma, params_.macdSma, params_.applied); 
   if (ret == INVALID_HANDLE){
      INDICATOR_ERROR(StringFormat(
         "[TMacd::GetHandle] iMACD(%s,%s,%u,%u,%u,%s) error: %i", 
         tf_.Symbol(), EnumToString(tf_.Period()), 
         params_.fastEma, params_.slowEma, params_.macdSma, EnumToString(params_.applied),
         GetLastError()));
   }
   return ret;
}

void TMacd::SetDigits(const string& _symbol){
   digits_ = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS) + 1;
}
 
}