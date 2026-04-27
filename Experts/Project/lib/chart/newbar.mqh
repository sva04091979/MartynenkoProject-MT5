#include "../tools/timeframe.mqh"
#include "log.mqh"

namespace Lib{

class TNewBar{
public:
   TNewBar();
   TNewBar(const string& _symbol, ENUM_TIMEFRAMES _tf);
   TNewBar(const string& _symbol);
   TNewBar(ENUM_TIMEFRAMES _tf);
   bool Reset();
   bool Reset(const string& _symbol, ENUM_TIMEFRAMES _tf);
   bool Reset(const string& _symbol);
   bool Reset(ENUM_TIMEFRAMES _t);
   bool Set(const string& _symbol, ENUM_TIMEFRAMES _tf);
   bool Set(const string& _symbol);
   bool Set(ENUM_TIMEFRAMES _t);
   datetime IsNewBar();
   datetime IsNewBar(datetime& _lastTime);

private:
   void ResetBase();
   datetime IsNewBarImpl();
   
private:
   TTimeframe tf_;
   datetime lastTime_;
};

TNewBar::TNewBar(void){
   ResetBase();
}

TNewBar::TNewBar(const string& _symbol, ENUM_TIMEFRAMES _tf):
   tf_(_symbol, _tf){
   ResetBase();
}

TNewBar::TNewBar(const string& _symbol):
   tf_(_symbol){
   ResetBase();
}

TNewBar::TNewBar(ENUM_TIMEFRAMES _tf):
   tf_(_tf){
   ResetBase();
}

bool TNewBar::Reset(){
   bool ret = tf_.Reset();
   if (ret){
      ResetBase();
   } 
   return ret;
}

bool TNewBar::Reset(const string& _symbol, ENUM_TIMEFRAMES _tf){
   bool ret = tf_.Reset(_symbol, _tf);
   if (ret){
      ResetBase();
   } 
   return ret;
}

bool TNewBar::Reset(const string& _symbol){
   bool ret = tf_.Reset(_symbol);
   if (ret){
      ResetBase();
   } 
   return ret;
}

bool TNewBar::Reset(ENUM_TIMEFRAMES _tf){
   bool ret = tf_.Reset(_tf);
   if (ret){
      ResetBase();
   } 
   return ret;
}

bool TNewBar::Set(const string& _symbol, ENUM_TIMEFRAMES _tf){
   bool ret = tf_.Set(_symbol, _tf);
   if (ret){
      ResetBase();
   } 
   return ret;
}

bool TNewBar::Set(const string& _symbol){
   bool ret = tf_.Set(_symbol);
   if (ret){
      ResetBase();
   } 
   return ret;
}

bool TNewBar::Set(ENUM_TIMEFRAMES _tf){
   bool ret = tf_.Set(_tf);
   if (ret){
      ResetBase();
   } 
   return ret;
}

void TNewBar::ResetBase(){
   lastTime_ = 0;
}

datetime TNewBar::IsNewBarImpl(){
   datetime time = tf_.Time();
   if (time > lastTime_){
      CHART_INFO(StringFormat("[TTimeframe::IsNewBar()] New bar on %s(%s)",tf_.Symbol(), EnumToString(tf_.Period())));
      return time;
   }
   return 0;
}

datetime TNewBar::IsNewBar(){
   datetime ret = IsNewBarImpl();
   if(ret){
      lastTime_ = ret;
   }
   return ret;
}

datetime TNewBar::IsNewBar(datetime& _lastTime){
   _lastTime = lastTime_;
   return IsNewBar();
}

}