#include "position.mqh"
#include "riskCtrl.mqh"

#include "log.mqh"

#include <Generic\HashMap.mqh>
#include <Generic\HashSet.mqh>

class TTrade{
public:
   void Control();
   void Open(Lib::ETradeDirect _direct);
   void CloseAll(Lib::ETradeDirect _direct);
   void CloseAll();
   void OnTradeTransaction(const MqlTradeTransaction& _trans,
                           const MqlTradeRequest& _request,
                           const MqlTradeResult& _result){}

private:
   bool makeTmpArray(int _size);
   static bool CopyTo(CHashSet<TPosition*>&  _set, TPosition*& _arr[]);

private:
   TPosition* tmpArray[];
   CHashSet<TPosition*> storage_;
   CHashSet<TPosition*> buy_;
   CHashSet<TPosition*> sell_;
};

void TTrade::Open(Lib::ETradeDirect _direct){
   TPosition* pos = new TPosition(_direct);
   double volume = TRisk::ComputeVolume();
   if (pos.Open(volume, in_slPoint) == TPosition::eError){
      PLATFORM_ERROR("[TTrade::Open] Open position error!");
      delete pos;
      return;
   }
   storage_.Add(pos);
   if (_direct>0){
      buy_.Add(pos);
   } else {
      sell_.Add(pos);
   }
}

void TTrade::Control(void){
   int size = storage_.Count();
   if (!CopyTo(storage_, tmpArray)){
      return;
   }
   for (int i = 0; i < size; ++i){
      TPosition* pos = tmpArray[i];
      if (pos.Control() == TPosition::eFinished){
         storage_.Remove(pos);
         if (pos.Direct() > 0){
            buy_.Remove(pos);
         } else {
            sell_.Remove(pos);
         }
         delete pos;
      }
   }
}

void TTrade::CloseAll(void){
   int size = storage_.Count();
   if (!CopyTo(storage_, tmpArray)){
      return;
   }
   for (int i = 0; i < size; ++i){
      TPosition* pos = tmpArray[i];
      if (pos.Close() == TPosition::eFinished){
         storage_.Remove(pos);
         if (pos.Direct() > 0){
            buy_.Remove(pos);
         } else {
            sell_.Remove(pos);
         }
         delete pos;
      }
   }
}

void TTrade::CloseAll(Lib::ETradeDirect _direct){
   CHashSet<TPosition*>* list = _direct > 0? &buy_: &sell_;
   int size = list.Count();
   if (!CopyTo(list, tmpArray)){
      return;
   }
   for (int i = 0; i < size; ++i){
      TPosition* pos = tmpArray[i];
      if (pos.Close() == TPosition::eFinished){
         storage_.Remove(pos);
         list.Remove(pos);
         delete pos;
      }
   }
}

bool TTrade::CopyTo(CHashSet<TPosition*>&  _set, TPosition*& _arr[]){
   int size = _set.Count();
   if (_set.CopyTo(_arr) != size){
      PLATFORM_ERROR("[TTrade::CopyTo] error!");
      return false;
   }
   return true;
}
