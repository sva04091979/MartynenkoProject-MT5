namespace Lib{

enum ECompare{
   eLess = -1,
   eEqual = 0,
   eGreater =1
};

enum EDirect{
   eDown = eLess,
   eNoDirect = eEqual,
   eUp = eGreater
};

enum ETradeDirect{
   eSell = eLess,
   eBuy = eGreater
};

string GetSymbol(const string& _symbol) { return _symbol == NULL?_Symbol:_symbol; }
string BoolToString(bool _val) {return _val? "true": "false";}

ENUM_TIMEFRAMES GetTimeframe(ENUM_TIMEFRAMES _tf) { return _tf == PERIOD_CURRENT? _Period:_tf; }

template<typename T1, typename T2>
ECompare Compare(const T1& _l, const T2& _r){
   if (_l == _r){
      return eEqual;
   }
   if (_l < _r){
      return eLess;
   }
   return eGreater;
}

ECompare Compare(double _l, double _r, int _digits){
   double res = NormalizeDouble(_l - _r, _digits);
   if(!res){
      return eEqual;
   }
   return res < 0.0? eLess: eGreater;
}

}