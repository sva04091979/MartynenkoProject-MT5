#include "../tools/timeframe.mqh"
#include "log.mqh"

namespace Lib{

class TIndicator{
public:
   ~TIndicator();

   bool Reset(bool _isShow);
   bool Reset(const string& _symbol, ENUM_TIMEFRAMES _tf, bool _isShow);
   bool Reset(const string& _symbol, bool _isShow);
   bool Reset(ENUM_TIMEFRAMES _t, bool _isShow);

   bool Init(bool _isShow);   
   bool Init(const string& _symbol, ENUM_TIMEFRAMES _tf, bool _isShow);
   bool Init(const string& _symbol, bool _isShow);
   bool Init(ENUM_TIMEFRAMES _t, bool _isShow);

   bool IsInit() const { return handle_!=INVALID_HANDLE; }
   bool HasReinited() const { return hasReinited_; }
   
   bool GetBuffer(double& _info, uint _buffer, uint _i);
   int GetBuffer(double& _info[], uint _buffer, uint _from);
   int GetBuffer(double& _info[], uint size, uint _buffer, uint _from);
   
   const TTimeframe* Timeframe() const { return &tf_; }
   int Digits() const {return digits_;}
   
protected:
   TIndicator(const string& _name, uint _buffers, bool _isSubwindow);
   bool InitImpl(bool _isShow);
   
private:
   int GetBufferImpl(double& _info[], uint size, uint _buffer, uint _from);
   bool Show(bool _isShow);
   void Free();
   virtual void SetDigits(const string& _symbol) = 0;
   virtual bool CheckParams() const = 0;
   virtual int GetHandle() const = 0;
protected:
   string name_;
   TTimeframe tf_;
   uint buffers_;
   int handle_;
   int digits_;
   bool isSubwindow_;
   bool isShow_;
   bool hasReinited_;
};

TIndicator::TIndicator(const string& _name, uint _buffers, bool _isSubwindow):
   name_(_name),
   buffers_(_buffers),
   handle_(INVALID_HANDLE),
   isSubwindow_(_isSubwindow), 
   isShow_(false),
   hasReinited_(false)
   {}

TIndicator::~TIndicator() {Free();}

bool TIndicator::Reset(const string& _symbol, ENUM_TIMEFRAMES _tf, bool _isShow){
   hasReinited_ = false;
   bool sybolCange = _symbol != tf_.Symbol();
   if (!tf_.Reset(_symbol, _tf) && IsInit()){
      return Show(_isShow);
   }
   SetDigits(_symbol);
   return InitImpl(_isShow);
}

bool TIndicator::Reset(bool _isShow){
   return Reset(_Symbol, _Period, _isShow);
}

bool TIndicator::Reset(const string& _symbol, bool _isShow){
   return Reset(_symbol, _Period, _isShow);
}

bool TIndicator::Reset(ENUM_TIMEFRAMES _tf, bool _isShow){
   return Reset(_Symbol, _tf, _isShow);
}

bool TIndicator::Init(const string& _symbol, ENUM_TIMEFRAMES _tf, bool _isShow){
   hasReinited_ = false;
   if (!tf_.Set(_symbol, _tf) && IsInit()){
      return Show(_isShow);
   }
   return InitImpl(_isShow);
}

bool TIndicator::Init(bool _isShow){
   return Init(_Symbol, _Period, _isShow);
}

bool TIndicator::Init(const string& _symbol, bool _isShow){
   return Init(_symbol, _Period, _isShow);
}

bool TIndicator::Init(ENUM_TIMEFRAMES _tf, bool _isShow){
   return Init(_Symbol, _tf, _isShow);
}

bool TIndicator::InitImpl(bool _isShow){
   hasReinited_ = true;
   Free();
   if (!CheckParams()){
      return false;
   }
   handle_ = GetHandle();
   if (handle_ == INVALID_HANDLE){
      return false;
   }
   if (!Show(_isShow)){
      IndicatorRelease(handle_);
      handle_ = INVALID_HANDLE;
      return false;      
   }
   return true;
}

bool TIndicator::GetBuffer(double& _info, uint _buffer, uint _i){
   double tmp[1];
   if (GetBufferImpl(tmp, 1, _buffer, _i) != 1){
      return false;
   }
   _info = tmp[0];
   return true;
}

int TIndicator::GetBuffer(double& _info[], uint _buffer, uint _from){
   return GetBufferImpl(_info, _info.Size(), _buffer, _from);
}

int TIndicator::GetBuffer(double& _info[], uint _size, uint _buffer, uint _from){
   int size = ArrayResize(_info, _size);
   if (size != _size){
      INDICATOR_ERROR(StringFormat("[TIndicator(%s)::GetBuffer] ArrayResize(&val[], %u) returned %i. Error: %i", name_, _size, size, GetLastError()));
      return -1;
   }
   return GetBufferImpl(_info, size, _buffer, _from);
}

int TIndicator::GetBufferImpl(double& _info[], uint _size, uint _buffer, uint _from){
   if (_buffer >= buffers_){
      INDICATOR_ERROR(StringFormat("[TIndicator(%s)::GetBufferImpl] Unexpected buffer %u. Has only %u buffers.", name_, _buffer, buffers_));
   }
   if (!_size){
      return 0;
   }
   int ret = CopyBuffer(handle_, _buffer, _from, _size, _info);
   if (ret < 0){
      INDICATOR_ERROR(StringFormat("[TIndicator(%s)::GetBufferImpl] CopyBuffer(%i,%u,%u,%u,&val[]) returned %i. Error: %i", name_, handle_, _buffer, _from, _size, ret, GetLastError()));
   } else if (ret < (int)_size){
      INDICATOR_WARNING(StringFormat("[TIndicator(%s)::GetBufferImpl] CopyBuffer(%i,%u,%u,%u,&val[]) returned %i, expected %u. Error: %i", name_, handle_, _buffer, _from, _size, ret, _size, GetLastError()));      
   }
   return ret;
}

bool TIndicator::Show(bool _isShow){
   _isShow = !MQLInfoInteger(MQL_TESTER) && _isShow && _Period == tf_.Period();
   if (_isShow == isShow_){
      return true;
   }
   if (_isShow){
      long win = isSubwindow_?ChartGetInteger(0,CHART_WINDOWS_TOTAL):0;
      if (!ChartIndicatorAdd(0,(int)win,handle_)){
         INDICATOR_ERROR(StringFormat("[TIndicator::Show] ChartIndicatorAdd(0,%lli,%i) Error: %i", win, handle_, GetLastError()));
         return false;
      }
   } else {
      long winStart = isSubwindow_?ChartGetInteger(0,CHART_WINDOWS_TOTAL)-1:0;
      for (long win = winStart ;win >= 0;--win){
         for (int i = ChartIndicatorsTotal(0,(int)win)-1; i>=0; --i){
            string name = ChartIndicatorName(0,(int)win,i);
            if (ChartIndicatorGet(0,(int)win,name) == handle_){
               ChartIndicatorDelete(0,(int)win,name);
            }
         }
      }
   }
   isShow_ = _isShow;
   return true;
}

void TIndicator::Free(void){
   if (handle_ == INVALID_HANDLE)
      return;
   Show(false);
   IndicatorRelease(handle_);
   handle_ = INVALID_HANDLE;
}

}