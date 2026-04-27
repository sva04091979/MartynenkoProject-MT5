input group "Common"
input double in_volume = 0.1; // Volume (/100$)
input uint in_slPoint = 150; // SL (pips)

input group "Fast MACD";
input ENUM_TIMEFRAMES in_fastMacdTf = PERIOD_M1; // Timeframe
input uint  in_fastMacdFastEma = 12; // Fast EMA
input uint  in_fastMacdSlowEma = 26; // Slow EMA
input uint  in_fastMacdSma = 9; // MACD SMA
input ENUM_APPLIED_PRICE in_fastMacdApplied = PRICE_CLOSE; // Applied price
input uint in_fastMacdFilter = 2; // Filter

input group "Slow MACD";
input ENUM_TIMEFRAMES in_slowMacdTf = PERIOD_M15; // Timeframe
input uint  in_slowMacdFastEma = 12; // Fast EMA
input uint  in_slowMacdSlowEma = 26; // Slow EMA
input uint  in_slowMacdSma = 9; // MACD SMA
input ENUM_APPLIED_PRICE in_slowMacdApplied = PRICE_CLOSE; // Applied price
input uint in_slowMacdFilter = 2; // Filter
