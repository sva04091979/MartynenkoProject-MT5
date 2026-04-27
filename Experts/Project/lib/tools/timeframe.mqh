#include "log.mqh"

namespace Lib{

class TTimeframe{
public:
   TTimeframe();
   TTimeframe(const string& _symbol, ENUM_TIMEFRAMES _tf);
   TTimeframe(const string& _symbol);
   TTimeframe(ENUM_TIMEFRAMES _tf);
   bool Reset();
   bool Reset(const string& _symbol, ENUM_TIMEFRAMES _tf);
   bool Reset(const string& _symbol);
   bool Reset(ENUM_TIMEFRAMES _tf);
   bool Set(const string& _symbol, ENUM_TIMEFRAMES _tf);
   bool Set(const string& _symbol);
   bool Set(ENUM_TIMEFRAMES _tf);

   string Symbol() const;
   ENUM_TIMEFRAMES Period() const;
   datetime Time(int _shift = 0) const;
   int BarShift(datetime _time, bool _exact = false) const { return iBarShift(symbol_, tf_, _time, _exact); }
   int Bars() const { return iBars(symbol_, tf_); }
   double Point() const { return SymbolInfoDouble(symbol_, SYMBOL_POINT); }
protected:
   string symbol_;
   ENUM_TIMEFRAMES tf_;
   bool isFixedTf_;
   bool isFixedSymbol_;
};

TTimeframe::TTimeframe(void) { Reset(); }

TTimeframe::TTimeframe(const string& _symbol, ENUM_TIMEFRAMES _tf) { Reset(_symbol, _tf); }

TTimeframe::TTimeframe(const string& _symbol) { Reset(_symbol); }

TTimeframe::TTimeframe(ENUM_TIMEFRAMES _tf) { Reset(_tf); }

bool TTimeframe::Reset(){
   bool ret = symbol_ != _Symbol || tf_ != _Period;
   symbol_ = _Symbol;
   tf_ = _Period;
   isFixedTf_ = false;
   isFixedSymbol_ = false;
   return ret;
}

bool TTimeframe::Reset(const string& _symbol, ENUM_TIMEFRAMES _tf){
   string symbol = GetSymbol(_symbol);
   ENUM_TIMEFRAMES tf = GetTimeframe(_tf);
   bool ret = symbol_ != symbol || tf_ != tf;
   symbol_ = symbol;
   tf_ = tf;
   isFixedTf_ = _tf == tf_;
   isFixedSymbol_ = _symbol == symbol_;
   return ret;
}

bool TTimeframe::Reset(const string& _symbol){
   string symbol = GetSymbol(_symbol);
   bool ret = symbol_ != symbol;
   symbol_ = symbol;
   tf_ = _Period;
   isFixedTf_ = false;
   isFixedSymbol_ = _symbol == symbol_;
   return ret;
}

bool TTimeframe::Reset(ENUM_TIMEFRAMES _tf){
   ENUM_TIMEFRAMES tf = GetTimeframe(_tf);
   bool ret = tf_ != tf;
   symbol_ = _Symbol;
   tf_ = tf;
   isFixedTf_ = _tf == tf_;
   isFixedSymbol_ = false;
   return ret;
}

bool TTimeframe::Set(const string& _symbol, ENUM_TIMEFRAMES _tf){
   bool ret = Set(_symbol);
   ret = Set(_tf) || ret;
   return ret;
}

bool TTimeframe::Set(const string& _symbol){
   if (isFixedSymbol_){
      return false;
   }
   string symbol = GetSymbol(_symbol);
   if(symbol == symbol_){
      return false;
   }
   symbol_ = symbol;
   return true;
}

bool TTimeframe::Set(ENUM_TIMEFRAMES _tf){
   if (isFixedTf_){
      return false;
   }
   ENUM_TIMEFRAMES tf = GetTimeframe(_tf);
   if(tf == tf_){
      return false;
   }
   tf_ = tf;
   return true;
}

string TTimeframe::Symbol() const { return symbol_; }

ENUM_TIMEFRAMES TTimeframe::Period() const { return tf_; }

datetime TTimeframe::Time(int _shift) const{
   datetime ret = iTime(symbol_, tf_, _shift);
   if (!ret){
      TOOLS_ERROR(StringFormat("[TTimeframe::Time()] Error %i due iTime(%s, %s, %i)", GetLastError(), symbol_, EnumToString(tf_), _shift));
   }
   return ret;   
}

}