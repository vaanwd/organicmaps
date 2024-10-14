#import <Foundation/Foundation.h>

#include "drape/color.hpp"

inline uint8_t ConvertColorComponentToHex(CGFloat color) {
  ASSERT_LESS_OR_EQUAL(color, 1.f, ("Extended sRGB color space is not supported"));
  ASSERT_GREATER_OR_EQUAL(color, 0.f, ("Extended sRGB color space is not supported"));
  static constexpr uint8_t kMaxChannelValue = 255;
  return color * kMaxChannelValue;
}

inline dp::Color GetDrapeColorFromUIColor(UIColor * color) {
  CGFloat fRed, fGreen, fBlue, fAlpha;
  [color getRed:&fRed green:&fGreen blue:&fBlue alpha:&fAlpha];

  const uint8_t red = ConvertColorComponentToHex(fRed);
  const uint8_t green = ConvertColorComponentToHex(fGreen);
  const uint8_t blue = ConvertColorComponentToHex(fBlue);
  const uint8_t alpha = ConvertColorComponentToHex(fAlpha);

  return dp::Color(red, green, blue, alpha);
}

inline UIColor * GetUIColorFromDrapeColor(dp::Color color) {
  return [UIColor colorWithRed:color.GetRedF() green:color.GetGreenF() blue:color.GetBlueF() alpha:1.f];
}
